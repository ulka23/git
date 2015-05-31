#include "builtin.h"
#include "color.h"
#include "parse-options.h"
#include "refs.h"
#include "run-command.h"

enum color {
	color_clear,
	color_bad,
	color_ok,
	color_flags
};

static const char *bash_color_codes[] = {
	"\\[\\e[0m\\]",
	"\\[\\e[31m\\]",
	"\\[\\e[32m\\]",
	"\\[\\e[1;34m\\]"
};
static const char *zsh_color_codes[] = {
	"%f",
	"%F{red}",
	"%F{green}",
	"%F{blue}"
};
static const char **color_codes;

static int zsh;
static int use_color;
static const char *describe_style;
static const char *state_separator = " ";
static int show_dirty;
static int show_stash;
static int show_untracked;

static const char * const prompt__helper_usage[] = {
	N_("git prompt--helper [--zsh] [--color] [--describe <style>] [--state-separator <separator>] [--show-dirty] [--show-stash] [--show-untracked]"),
	NULL
};

static struct option prompt__helper_options[] = {
	OPT_BOOL(0, "zsh", &zsh, N_("output suitable for zsh")),
	OPT_BOOL(0, "color", &use_color, N_("output for colored prompt")),
	OPT_STRING(0, "describe", &describe_style, N_("style"),
		   N_("describe detached head using the given style")),
	OPT_STRING(0, "state-separator", &state_separator, N_("separator"),
		   N_("separator between branch name and repo state flags")),
	OPT_BOOL(0, "show-dirty", &show_dirty, N_("show dirty state")),
	OPT_BOOL(0, "show-stash", &show_stash, N_("show stash state")),
	OPT_BOOL(0, "show-untracked", &show_untracked, N_("show untracked files")),
	OPT_END(),
};

void print_with_color(enum color color, const char * s)
{
	if (use_color)
		printf("%s", color_codes[color]);
	printf("%s", s);
}

static char *describe()
{
	struct strbuf describe_out = STRBUF_INIT;
	struct child_process describe_cmd = CHILD_PROCESS_INIT;

	argv_array_init(&describe_cmd.args);
	argv_array_push(&describe_cmd.args, "describe");
	if (describe_style) {
		if (!strcmp(describe_style, "contains"))
			argv_array_push(&describe_cmd.args, "--contains");
		else if (!strcmp(describe_style, "branch")) {
			argv_array_push(&describe_cmd.args, "--contains");
			argv_array_push(&describe_cmd.args, "--all");
		}
	} else {
		argv_array_push(&describe_cmd.args, "--tags");
		argv_array_push(&describe_cmd.args, "--exact-match");
	}
	argv_array_push(&describe_cmd.args, "HEAD");
	describe_cmd.git_cmd = 1;

	capture_command(&describe_cmd, &describe_out, 0);

	argv_array_clear(&describe_cmd.args);

	if (describe_out.len > 1) {
		/* describe's output ends with newline, strip it */
		strbuf_setlen(&describe_out, describe_out.len-1);
		return strbuf_detach(&describe_out, NULL);
	}

	return NULL;
}

int cmd_prompt__helper(int argc, const char **argv, const char *prefix)
{
	unsigned char sha1[20];
	int flag;
	char *refname;
	enum color refname_color;
	int dirty_worktree = 0, dirty_index = 0, is_orphan = 0, has_stash = 0;
	int has_untracked = 0;

	git_config(git_default_config, NULL);

	argc = parse_options(argc, argv, prefix, prompt__helper_options,
			     prompt__helper_usage, 0);
	if (argc)
		usage_with_options(prompt__helper_usage,
				   prompt__helper_options);

	if (use_color) {
		if (zsh)
			color_codes = zsh_color_codes;
		else
			color_codes = bash_color_codes;
	}

	refname = resolve_refdup("HEAD", 0, sha1, &flag);
	if (!refname)
		die("No HEAD ref");
	else if (flag & REF_ISSYMREF) {
		refname = shorten_unambiguous_ref(refname, 0);
		refname_color = color_ok;
	} else {
		char *described = describe();
		if (described) {
			refname = xstrfmt("(%s)", described);
			free(described);
		} else {
			const char *unique = find_unique_abbrev(sha1,
							      DEFAULT_ABBREV);
			refname = xstrfmt("(%s...)", unique);
		}
		refname_color = color_bad;
	}

	if (!is_inside_work_tree()) {
		show_dirty = 0;
		show_stash = 0;
		show_untracked = 0;
	}

	if (show_dirty)
		git_config_get_maybe_bool("bash.showDirtyState",
					  &show_dirty);
	if (show_dirty) {
		static const char *diff_args[] = {
			"diff", "--no-ext-diff", "--quiet", NULL };

		dirty_worktree = cmd_diff(ARRAY_SIZE(diff_args)-1,
					  diff_args, prefix);

		is_orphan = get_sha1("HEAD", sha1) ? 1 : 0;
		if (!is_orphan) {
			static const char *diff_index_args[] = {
				"diff-index", "--cached", "--quiet", "HEAD",
				"--", NULL };
			dirty_index = cmd_diff_index(ARRAY_SIZE(diff_index_args)-1,
						     diff_index_args, prefix);
		}
	}

	if (show_stash)
		has_stash = get_sha1("refs/stash", sha1) ? 0 : 1;

	if (show_untracked)
		git_config_get_maybe_bool("bash.showUntrackedFiles",
					  &show_untracked);
	if (show_untracked) {
		struct strbuf ls_files_out = STRBUF_INIT;
		struct child_process ls_files_cmd = CHILD_PROCESS_INIT;

		argv_array_init(&ls_files_cmd.args);
		argv_array_pushl(&ls_files_cmd.args, "ls-files", "--others",
				 "--exclude-standard", "--error-unmatch",
				 "--", ":/*", NULL);
		ls_files_cmd.git_cmd = 1;

		has_untracked = !capture_command(&ls_files_cmd, &ls_files_out, 0);
		argv_array_clear(&ls_files_cmd.args);
		strbuf_release(&ls_files_out);
	}

	if (is_bare_repository()) {
		print_with_color(refname_color, "BARE:");
		printf("%s", refname);
	} else if (is_inside_git_dir())
		print_with_color(refname_color, "GIT_DIR!");
	else
		print_with_color(refname_color, refname);

	if (dirty_worktree || dirty_index || is_orphan || has_stash ||
	    has_untracked) {
		print_with_color(color_clear, state_separator);

		if (dirty_worktree)
			print_with_color(color_bad, "*");
		if (dirty_index)
			print_with_color(color_ok, "+");
		if (is_orphan)
			print_with_color(color_ok, "#");
		if (has_stash)
			print_with_color(color_flags, "$");
		if (has_untracked)
			print_with_color(color_bad, zsh ? "%%" : "%");
	}

	free(refname);

	return 0;
}
