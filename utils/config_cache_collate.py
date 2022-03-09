#!/usr/bin/env python3

# try to collate the descriptive output of configure with a config.cache file.

# a config.cache file will have lines like:
# ac_cv_func_catgets=${ac_cv_func_catgets=yes}
# ac_cv_func_chown=${ac_cv_func_chown=yes}

# configure will produce descriptive output like this:
# checking for catgets... yes
# checking for chown... yes

# unfortunately, the config.cache file isn't in the same order as the configure
# output.  matching them up line-by-line is tedious.

# the purpose of this script is to at least make an attempt at matching them
# up in an automated fashion, to reduce the tedium for the human which makes
# a final pass over the resulting file.

# re: the code quality of this script:
# for 31 days, the devil himself ate nothing but computer science textbooks,
# refusing to defecate the entire time.  on the 32nd day, he defecated, and
# the following source code was found in his stool:

prefixes = ["am_cv_", "ac_cv_", "gl_cv_", "gt_cv_", "gzip_cv_"]

# we don't ever include these in config.cache:
skippable_prefixes = [
    "ac_cv_prog_",  # never cache the path to a program (let the user dictate).
    "ac_cv_path_",  # never cache the path to a program (let the user dictate).
    "gl_cv_next_",  # these seem to be follow-up calls after ac_cv_header_*?
    "ac_cv_sizeof_",  # these will be different on a G5.
]

# these just create noise.
banned_keys = ["in"]

import sys
import subprocess
import re
import math
import os

debug = False


def usage_and_die():
    sys.stderr.write("""❌ Error: bad args.

Usage: %s <pkgspec> <os.cpu>
e.g. %s gzip-1.11 leopard.g4e

Usage: %s <config.cache> <install.log> [<site.cache>]
e.g. %s /tmp/config.cache /tmp/install.log
e.g. %s /tmp/config.cache /tmp/install.log ~/tigersh/config.cache/tiger.cache
""" % (sys.argv[0], sys.argv[0], sys.argv[0], sys.argv[0], sys.argv[0]))
    sys.exit(1)


def process_cmdline():
    if len(sys.argv) < 3:
        usage_and_die()

    args = sys.argv[1:]
    if args[-1] == "--debug":
        global debug
        debug = True
        args = args[:-1]

    if len(args) == 2:
        return args + [None]
    elif len(args) == 3:
        return args
    else:
        usage_and_die()


def generate_and_run_extract_script(pkgspec, os_cpu):
    script = """

set -e -o pipefail
pkgspec=%s
os_cpu=%s
binpkg=$pkgspec.$os_cpu.tar.gz

cd /tmp
rm -rf $pkgspec
cat /Users/cell/leopard.sh/binpkgs/$binpkg | gunzip | tar x

rm -f /tmp/1 /tmp/2 /tmp/3

os=$(echo $os_cpu | cut -d. -f1)
cat $pkgspec/share/$os.sh/$pkgspec/config.cache.gz \
    | gunzip \
    > /tmp/1

cat $pkgspec/share/$os.sh/$pkgspec/install-$pkgspec.sh.log.gz \
    | gunzip \
    > /tmp/2

cat ~/leopard.sh/${os}sh/config.cache/${os}.cache > /tmp/3
cat ~/leopard.sh/${os}sh/config.cache/disabled.cache >> /tmp/3

    """ % (pkgspec, os_cpu)

    fd = open("/tmp/script.sh", "w")
    fd.write(script)
    fd.close()

    subprocess.check_call("bash /tmp/script.sh", shell=True)


def generate_and_run_scrub_script():
    script = """

set -e -o pipefail

rm -f /tmp/1. /tmp/2. /tmp/3.

cd /tmp

cat /tmp/1 \
    | ( grep -v '^#' || true ) \
    | ( grep -v '^$' || true ) \
    | ( grep '=\${' || true ) \
    | sort \
    | uniq \
    > /tmp/1.
mv /tmp/1. /tmp/1

if test -e /tmp/3 ; then
    cat /tmp/3 \
        | ( grep -v '^#' || true ) \
        | ( grep -v '^$' || true ) \
        | ( grep '=\${' || true ) \
        | sort \
        | uniq \
        > /tmp/3.
    mv /tmp/3. /tmp/3
fi

cat /tmp/2 \
    | sed 's/(cached) //' \
    > /tmp/2.
mv /tmp/2. /tmp/2

start2=$(egrep -n 'configure: (creating|loading) cache config.cache' /tmp/2 | sed 's/:.*//')
test -n "$start2"
start2=$(echo "$start2 + 1" | bc)
tail -n+$start2 /tmp/2 > /tmp/2.
mv /tmp/2. /tmp/2

end2=$(grep -n 'configure: updating cache config.cache' /tmp/2 | sed 's/:.*//')
test -n "$end2"
end2=$(echo "$end2 - 1" | bc)
head -n$end2 /tmp/2 > /tmp/2.
mv /tmp/2. /tmp/2

cat /tmp/2 \
    | ( grep '^checking' || true ) \
    | sort \
    | uniq \
    > /tmp/2.
mv /tmp/2. /tmp/2

"""

    fd = open("/tmp/script.sh", "w")
    fd.write(script)
    fd.close()

    subprocess.check_call("bash /tmp/script.sh", shell=True)


def load_cache_lines(fpath):
    if not os.path.exists(fpath):
        return []
    fd = open(fpath)
    cache_lines = []
    for line in fd.readlines():
        line.rstrip()
        cache_lines.append(line.rstrip())
    fd.close()
    # a cache_line will look like:
    # ac_cv_c_bigendian=${ac_cv_c_bigendian=yes}
    return cache_lines


def load_description_pairs(fpath):
    fd = open(fpath)
    description_lines = []
    for line in fd.readlines():
        description_line = line.rstrip()
        description_head = get_description_head(description_line).lower()
        description_lines.append((description_line, description_head))
    fd.close()
    # a description line will look like:
    # checking whether byte ordering is bigendian... yes
    return description_lines


def strip_prefixes(s):
    for prefix in prefixes:
        if s.startswith(prefix):
            s = s[len(prefix):]
    return s


def get_description_head(description_line):
    match = re.search('(.*?)\.\.\.', description_line)
    if match is None:
        return description_line
    return match.group(1)


def get_description_tail(description_line):
    match = re.search('.*\.\.\. (.*$)', description_line)
    if match is None:
        return None
    return match.group(1)


def powerset(parts):
    "given [a, b, c], return [[a], [b], [c], [a,b], [b,c], [a,b,c]]"
    "(except that it elides single-character parts)"
    powerset = []
    num_parts_to_combine = len(parts)
    while num_parts_to_combine > 1:
        start = 0
        while start + num_parts_to_combine <= len(parts):
            subset = parts[start:start+num_parts_to_combine]
            powerset.append(subset)
            start += 1
        num_parts_to_combine -= 1
    for part in parts:
        powerset.append([part])
    return powerset


def get_correlations(keys, description_pairs, desc_word_weights, shell_var, shell_value):

    def gen_line_scores(description_pairs, shell_value):
        filtered_desc_lines = []
        for (desc_line, desc_head) in description_pairs:
            if shell_value is None:
                line_score = 0.5
                filtered_desc_lines.append(desc_line, desc_head, line_score)
            else:
                tail = get_description_tail(desc_line)
                if tail is None:
                    line_score = 1
                else:
                    tail = tail.lower()
                    if shell_value in tail:
                        line_score = 2
                        if shell_value == tail:
                            line_score = 4
                    else:
                        line_score = 0
                if line_score > 0:
                    filtered_desc_lines.append((desc_line, desc_head, line_score))
        return filtered_desc_lines

    def gen_scored(filtered_desc_lines, key_sets, desc_word_weights):
        scored = []

        # special case:
        # ac_cv_func_foobar -> "checking for foobar..." is a known 100% match.
        # gl_cv_func_foobar -> "checking for foobar..." is a known 100% match.
        for prefix in ["ac_cv_func_", "gl_cv_func_"]:
            if shell_var.startswith(prefix):
                func_name = shell_var.split(prefix)[1]
                for (desc_line, desc_head, line_score) in filtered_desc_lines:
                    if desc_head == "checking for %s" % func_name:
                        score =  999
                        explain = ""
                        if debug:
                            explain = "\n  explain: %s* special case" % prefix
                        scored = [(score, desc_line + explain)]

        # gl_cv_func_foobar_works -> "checking whether foobar works..." is a known 100% match.
        if shell_var.startswith("gl_cv_func_") and shell_var.endswith("_works"):
            func_name = shell_var.split("gl_cv_func_")[1][:-6]
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                if desc_head == "checking whether %s works" % func_name:
                    score =  999
                    explain = ""
                    if debug:
                        explain = "\n  explain: gl_cv_func_* special case"
                    scored = [(score, desc_line + explain)]

        # special case:
        # ac_cv_type_nlink_t -> "checking for nlink_t..." is a known 100% match.
        if shell_var.startswith("ac_cv_type_"):
            type_name = shell_var.split("ac_cv_type_")[1]
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                if desc_head == "checking for %s" % type_name:
                    score =  999
                    explain = ""
                    if debug:
                        explain = "\n  explain: ac_cv_type_* special case"
                    scored = [(score, desc_line + explain)]

        # special case:
        # gl_cv_bitsizeof_wchar_t -> "checking for bit size of wchar_t..." is a known 100% match.
        if shell_var.startswith("gl_cv_bitsizeof_"):
            type_name = shell_var.split("gl_cv_bitsizeof_")[1]
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                if desc_head == "checking for bit size of %s" % type_name:
                    score =  999
                    explain = ""
                    if debug:
                        explain = "\n  explain: gl_cv_bitsizeof_* special case"
                    scored = [(score, desc_line + explain)]

        # special case:
        # ac_cv_have_decl_fcloseall -> "checking whether fcloseall is declared..."
        # is a known 100% match.
        if shell_var.startswith("ac_cv_have_decl_"):
            decl_name = shell_var.split("ac_cv_have_decl_")[1]
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                if desc_head == "checking whether %s is declared" % decl_name:
                    score =  999
                    explain = ""
                    if debug:
                        explain = "\n  explain: ac_cv_have_decl_* special case"
                    scored = [(score, desc_line + explain)]

        # special case:
        # ac_cv_header_limits_h -> "checking for limits.h..." is a known 100% match.
        if shell_var.startswith("ac_cv_header_"):
            header_name = shell_var.split("ac_cv_header_")[1]
            if header_name.endswith("_h"):
                header_name = header_name[:-2] + ".h"
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                if desc_head == "checking for %s" % header_name:
                    score =  999
                    explain = ""
                    if debug:
                        explain = "\n  explain: ac_cv_header_* special case"
                    scored = [(score, desc_line + explain)]

        # if no special-case applies, use a heuristic approach based on weighted sub-matches:
        if len(scored) == 0:
            for (desc_line, desc_head, line_score) in filtered_desc_lines:
                partial_factor = 1.0
                exact_factor = 3.0
                explain = "\n  explain:"
                explain += " l(%0.1f)" % line_score

                desc_head_words = desc_head.split()

                # drop "checking", "checking for" and "checking whether" prefixes.
                if desc_head_words[0] == "checking":
                    if desc_head_words in ["for", "whether"]:
                        desc_head_words = desc_head_words[1:]
                    else:
                        desc_head_words = desc_head_words[2:]

                # special-case description edits:
                special_case_words = []
                for word in desc_head_words:
                    if word.startswith("-l") and len(word) > 2:
                        # for "-lfoobar", also try "foobar" as a key:
                        special_case_words.append(word[2:])
                if len(special_case_words) > 0:
                    if debug:
                        print("special-case words1: %s -> %s" % (desc_line, special_case_words))
                    desc_head_words += special_case_words

                special_case_words = []
                for word in desc_head_words:
                    if "-" in word:
                        # for "foo-bar", also try "foo_bar" and "foobar":
                        special_case_words.append(word.replace("-", "_"))
                        special_case_words.append(word.replace("-", ""))
                if len(special_case_words) > 0:
                    if debug:
                        print("special-case words2: %s -> %s" % (desc_line, special_case_words))
                    desc_head_words += special_case_words

                special_case_words = []
                for word in desc_head_words:
                    special_word = word
                    if special_word.startswith("<") and special_word.endswith(">"):
                        special_word = special_word[1:-1]
                    if special_word.startswith("(") and special_word.endswith(")"):
                        special_word = special_word[1:-1]
                    if special_word.startswith("'") and special_word.endswith("'"):
                        special_word = special_word[1:-1]
                    special_word = special_word.\
                        replace(".h", "_h").\
                        replace("//", "double_slash").\
                        replace("/", "_")
                    if word != special_word:
                        special_case_words.append(special_word)
                if len(special_case_words) > 0:
                    if debug:
                        print("special-case words3: %s -> %s" % (desc_line, special_case_words))
                    desc_head_words += special_case_words

                score = 0
                for key_set in key_sets:
                    partial_score = 0
                    exact_score = 0

                    all_keys_partially_match = True
                    for key in key_set:
                        if key not in desc_head:
                            all_keys_partially_match = False
                            break
                    if all_keys_partially_match:
                        partial_score = 0
                        explain += " | p["
                        for key in key_set:
                            weight = partial_factor * desc_word_weights.get(key, 0.2)
                            explain += ",%s=%0.1f" % (key, weight)
                            partial_score += weight
                        explain += "](%0.1f)" % partial_score

                    all_keys_exactly_match = True
                    for key in key_set:
                        if key not in desc_head_words:
                            all_keys_exactly_match = False
                            break
                    if all_keys_exactly_match:
                        exact_score = 0
                        explain += " | e["
                        for key in key_set:
                            weight = exact_factor * desc_word_weights.get(key, 0.25)
                            explain += ",%s=%0.1f" % (key, weight)
                            exact_score += weight
                        explain += "](%0.1f)" % exact_score

                    score += partial_score + exact_score

                if score > 0:
                    if not debug:
                        explain = ""
                    scored.append((score * line_score, desc_line + explain))

        scored.sort()
        return scored

    shell_value = shell_value.lower()
    filtered_desc_lines = gen_line_scores(description_pairs, shell_value)
    key_sets = powerset(keys)
    scored_correlations = gen_scored(filtered_desc_lines, key_sets, desc_word_weights)

    # edit as needed when debugging:
    # if shell_var == "gl_cv_func_malloc_0_nonnull":
    #     import pprint
    #     print("###=> dump:")
    #     print("shell_value")
    #     pprint.pprint(shell_value)
    #     print("filtered_desc_lines")
    #     pprint.pprint(filtered_desc_lines)
    #     print("key_sets")
    #     pprint.pprint(key_sets)
    #     print("scored_correlations")
    #     pprint.pprint(scored_correlations)

    return scored_correlations


def split_slug(slug):
    """
    behavior:
    a => [a]
    _a => [_a]
    a_b => [a, b]
    a__b => [a, _b]
    _a___b => [_a, __b]
    foo___bar_t => [foo, __bar, t]
    """
    def consume_word(slug, is_first_word):
        word = ""

        # capture any leading underscores:
        did_skip_first_underscore = is_first_word
        while True:
            if len(slug) == 0:
                return (word, slug)
            ch = slug[0]
            if ch == '_':
                if not did_skip_first_underscore:
                    did_skip_first_underscore = True
                else:
                    word += ch
                slug = slug[1:]
                continue
            else:
                break
        
        # capture the non-underscore chars:
        while True:
            if len(slug) == 0:
                return (word, slug)
            ch = slug[0]
            if ch != '_':
                word += ch
                slug = slug[1:]
                continue
            else:
                break

        return (word, slug)

    words = []
    is_first = True
    while len(slug) > 0:
        (word, slug) = consume_word(slug, is_first)
        if len(word) > 0:
            words.append(word)
        is_first = False
    return words


def subslug_powerset(slug):
    "given a_b_c, return [a, b, c, a_b, b_c, a_b_c]"
    "(except that it elides single-character parts)"

    def pre_filter(keys):
        keys2 = []
        for k in keys:
            if k in banned_keys:
                continue
            keys2.append(k.lower())
        return keys2

    def make_powerset(keys):
        powerset = []
        num_parts_to_combine = len(keys)
        while num_parts_to_combine > 1:
            start = 0
            while start + num_parts_to_combine <= len(keys):
                word = "_".join(keys[start : start+num_parts_to_combine])
                powerset.append(word)
                start += 1
            num_parts_to_combine -= 1
        powerset += keys
        return powerset

    def post_filter(keys):
        keys2 = []
        for k in keys:
            if len(k) < 2:
                continue
            keys2.append(k)
        return keys2

    return post_filter(make_powerset(pre_filter(split_slug(slug))))


def parse_cache_line(cache_line):
    # given a line like 'ac_cv_build=${ac_cv_build=powerpc-apple-darwin9.8.0}',
    # return ('ac_cv_build', 'powerpc-apple-darwin9.8.0')
    shell_var = re.search('(.*?)=', cache_line).group(1)
    pattern = shell_var + '=\${' + shell_var + "='?(.*?)'?}"
    match = re.search(pattern, cache_line)
    if match is None:
        return (shell_var, None)
    else:
        shell_value = re.search(pattern, cache_line).group(1)
        return (shell_var, shell_value)


def compute_description_word_frequencies(description_pairs):
    d = {}
    for (line, head) in description_pairs:
        for word in head.split():
            if word in d:
                d[word] += 1
            else:
                d[word] = 1
    return d


def compute_word_weights(desc_word_freqs):
    weights = {}
    for (word, count) in desc_word_freqs.items():
        # weight = 1.0 / math.sqrt(count)
        weight = 1.0 / count
        weights[word] = weight
        # print("%s %s %0.3f" % (word, count, weight))
    return weights


def reconcile_config_and_site_caches(cache_lines, site_lines):
    site_d = {}
    for site_line in site_lines:
        (site_var, site_value) = parse_cache_line(site_line)
        site_d[site_var] = (site_value, site_line)

    cache_lines2 = []
    diff_lines = []
    status_d = {}
    for cache_line in cache_lines:
        (cache_var, cache_value) = parse_cache_line(cache_line)
        if cache_var not in site_d:
            # not in site.cache: process it.
            status_d[cache_var] = "new"
            cache_lines2.append(cache_line)
            continue
        (site_value, site_line) = site_d[cache_var]
        if site_value == cache_value:
            # already in site.cache, skip.
            status_d[cache_var] = "skipped"
            continue
        else:
            # value differs from site.cache.
            status_d[cache_var] = "changed"
            diff_lines.append((site_line, cache_line))
    return (cache_lines2, diff_lines, status_d)


if __name__ == "__main__":

    (arg1, arg2, arg3) = process_cmdline()

    have_site_cache = False
    if os.path.exists(arg1) and os.path.exists(arg2):
        sys.stderr.write("Using files %s and %s\n" % (arg1, arg2))
        subprocess.check_call("cp %s /tmp/1" % arg1, shell=True)
        subprocess.check_call("cp %s /tmp/2" % arg2, shell=True)
        subprocess.check_call("rm -f /tmp/3", shell=True)
        if arg3 is not None:
            if not os.path.exists(arg3):
                usage_and_die()
            have_site_cache = True
            subprocess.check_call("rm -f /tmp/3 ; cp %s /tmp/3" % arg3, shell=True)
    else:
        pkgspec = arg1
        os_cpu = arg2
        if arg3 is not None:
            usage_and_die()
        sys.stderr.write("Using pkgspec %s from %s\n" % (pkgspec, os_cpu))
        generate_and_run_extract_script(pkgspec, os_cpu)

    generate_and_run_scrub_script()

    cache_lines = load_cache_lines("/tmp/1")
    description_pairs = load_description_pairs("/tmp/2")
    site_lines = load_cache_lines("/tmp/3")

    (cache_lines, diff_lines, status_d) = reconcile_config_and_site_caches(cache_lines, site_lines)

    desc_word_freqs = compute_description_word_frequencies(description_pairs)
    desc_word_weights = compute_word_weights(desc_word_freqs)
    
    for cache_line in cache_lines:
        (shell_var, shell_value) = parse_cache_line(cache_line)

        should_skip = False
        for prefix in skippable_prefixes:
            if shell_var.startswith(prefix):
                should_skip = True
        if should_skip:
            status_d[shell_var] = "skipped"
            continue
        
        slug = strip_prefixes(shell_var)
        words = subslug_powerset(slug)
        correlations = get_correlations(words, description_pairs, desc_word_weights, shell_var, shell_value)

        print()
        if len(correlations) == 0:
            print("# Unable to find any correlation for this config.cache line: %s (%s)" % (cache_line, words))
            print(cache_line)
        else:
            if debug:
                print(cache_line)
                print(shell_var, "=", shell_value)
                # print(words, "used: %s" % used_word)
            if len(correlations) > 1:
                for (score, desc) in correlations:
                    # print("# %0.1f %s" % (score, desc))
                    print("%0.1f # %s" % (score, desc))
                print("# --- best guess:")
            (_, last_desc) = correlations[-1]
            print("# %s" % last_desc)
            print(cache_line)

    for (site_line, cache_line) in diff_lines:
        print()
        print("# This value has changed:")
        print("# from: %s" % site_line)
        print("# to: %s" % cache_line)
    
    for k in sorted(status_d.keys()):
        status = status_d[k]
        if status != "skipped":
            sys.stderr.write("%s: %s\n" % (status_d[k], k))
