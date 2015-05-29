#include "builtin.h"
#include "parse-options.h"
#include "refs.h"

static const char * const prompt__helper_usage[] = {
	N_("git prompt--helper"),
	NULL
};

static struct option prompt__helper_options[] = {
	OPT_END(),
};

int cmd_prompt__helper(int argc, const char **argv, const char *prefix)
{
	unsigned char sha1[20];
	int flag;
	char *refname;

	git_config(git_default_config, NULL);

	argc = parse_options(argc, argv, prefix, prompt__helper_options,
			     prompt__helper_usage, 0);
	if (argc)
		usage_with_options(prompt__helper_usage,
				   prompt__helper_options);

	refname = resolve_refdup("HEAD", 0, sha1, &flag);
	if (!refname)
		die("No HEAD ref");
	else if (flag & REF_ISSYMREF)
		refname = shorten_unambiguous_ref(refname, 0);
	else
		return 0;

	if (is_bare_repository())
		printf("BARE:%s", refname);
	else if (is_inside_git_dir())
		printf("GIT_DIR!");
	else
		printf("%s", refname);

	free(refname);

	return 0;
}
