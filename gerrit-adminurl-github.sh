#!/bin/sh

die() {
	local m="$1"
	echo "FATAL: ${m}" >&2
	exit 1
}

mycurl() {
	local method="$1"; shift
	local url="$1"; shift
	local data="$1"; shift

	curl \
		$([ -z "${DEBUG}" ] && echo --silent || echo --verbose) \
		--fail \
		-X "${method}" \
		-H "Authorization: token ${GITHUB_TOKEN}" \
		-H "Accept: application/json" \
		-H "Content-Type: application/json" \
		--data "${data}" \
		"${url}" \
		> /dev/null \
		|| die "HTTP request failed"
}

project_convert() {
	local project="$1"; shift

	if [ -n "${GITHUB_PROJECT_CONVERT}" ]; then
		project="$(echo "${project}" | sed "${GITHUB_PROJECT_CONVERT}")"
	fi

	echo "${project}"
}

create_project() {
	local branch="master"
	while [ -n "$1" ]; do
		opt="${1}"
		val="${1#*=}"
		case "${opt}" in
			--*);;
			--) break;;
			*) break;;
		esac
		shift

		case "${opt}" in
			--branch=*)
				branch="${val}"
				;;
			--branch)
				branch="${1}"
				shift
				;;
			--*)
				;;
		esac
	done

	local project="$1"
	[ -n "${project}" ] || die "Project is missing"
	shift

	project="$(project_convert "${project}")"

	local data="$(cat << __EOF__
{
	"name": "${project}",
	"default_branch": "${branch}",
	"private": true
}
__EOF__
)"

	echo "Creating '${project}' branch '${branch}'"
	mycurl POST "${GITHUB_CREATE_URL}" "${data}"
}

delete_project() {
	local really
	local force

	[ "$1" = "delete" ] || die "Expecting 'delete' subsubcommand"
	shift

	while [ -n "$1" ]; do
		opt="${1}"
		val="${1#*=}"
		case "${opt}" in
			--*);;
			--) break;;
			*) break;;
		esac
		shift

		case "${opt}" in
			--yes-really-delete)
				really=1
				;;
			--force)
				force=1
				;;
			--*)
				;;
		esac
	done

	local project="$1"
	[ -n "${project}" ] || die "Project is missing"
	shift

	project="$(project_convert "${project}")"

	[ -n "${really}" ] || die "Missing really"
	[ -n "${force}" ] || die "Missing force"

	echo "Deleting '${project}'"
	mycurl DELETE "${GITHUB_REPO_URL}/${project}" ""
}

set_head() {
	local head

	project="$1"
	[ -n "${project}" ] || die "Project is missing"
	shift
	[ "$1" = "--" ] && shift

	while [ -n "$1" ]; do
		opt="${1}"
		val="${1#*=}"
		case "${opt}" in
			--*);;
			--) break;;
			*) break;;
		esac
		shift

		case "${opt}" in
			--new-head=*)
				head="${val}"
				;;
			--new-head)
				head="$1"
				shift
				;;
			--*)
				;;
		esac
	done

	[ -n "${head}" ] || die "Missing head"

	die "set head is not supported"
}

DEBUG=

while [ -n "$1" ]; do
	opt="${1}"
	val="${1#*=}"
	case "${opt}" in
		--*);;
		--) break;;
		*) break;;
	esac
	shift

	case "${opt}" in
		--debug)
			DEBUG=1
			;;
		--config=*)
			. "${val}" || die "Cannot read config"
			;;
		--config)
			. "${1}" || die "Cannot read config"
			shift
			;;
		*)
			die "Inavlid option '${opt}'"
	esac
done

[ -n "${GITHUB_CREATE_URL}" ] || die "GITHUB_CREATE_URL missing"
[ -n "${GITHUB_REPO_URL}" ] || die "GITHUB_REPO_URL missing"
[ -n "${GITHUB_TOKEN}" ] || die "GITHUB_TOKEN missing"

set -- ${SSH_ORIGINAL_COMMAND}

[ "$1" = "gerrit" ] || die "Expecting 'gerrit' command"
shift
command="$1"
[ -n "${command}" ] || die "Expecting subcommand"
shift

case "${command}" in
	create-project)
		create_project "$@"
		;;
	deleteproject)
		delete_project "$@"
		;;
	set-head)
		set_head "$@"
		;;
	*)
		die "Unsupported subcommand '${command}'"
		;;
esac
