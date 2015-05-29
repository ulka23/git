#include "builtin.h"
#include "color.h"
#include "parse-options.h"
#include "refs.h"

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

static const char * const prompt__helper_usage[] = {
	N_("git prompt--helper [--zsh] [--color]"),
	NULL
};

static struct option prompt__helper_options[] = {
	OPT_BOOL(0, "zsh", &zsh, N_("output suitable for zsh")),
	OPT_BOOL(0, "color", &use_color, N_("output for colored prompt")),
	OPT_END(),
};

void print_with_color(enum color color, const char * s)
{
	if (use_color)
		printf("%s", color_codes[color]);
	printf("%s", s);
}

int cmd_prompt__helper(int argc, const char **argv, const char *prefix)
{
	unsigned char sha1[20];
	int flag;
	char *refname;
	enum color refname_color;

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
	} else
		return 0;

	if (is_bare_repository()) {
		print_with_color(refname_color, "BARE:");
		printf("%s", refname);
	} else if (is_inside_git_dir())
		print_with_color(refname_color, "GIT_DIR!");
	else
		print_with_color(refname_color, refname);

	free(refname);

	return 0;
}
