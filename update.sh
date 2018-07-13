#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

defaultPhpVersion='7.2'
declare -A phpVersions=(
	[2.3]='7.1'
	[2.4]='7.1'
)

travisEnv=
for version in "${versions[@]}"; do

	listVersion=$(git ls-remote --tags https://github.com/changi67/itop/ | awk -F'/' '{print $3}' | egrep -v '(@|-)' | egrep -v '^(0|1)')

	for fullVersion in $listVersion; do
		major=${version//./}
		minor=${fullVersion//./}
		minor=${minor::(-1)}
		if [ "$major" -ne "$minor" ]; then
			echo "$fullVersion not compatible with current version $version";
			continue;
		fi

		if [ -f "${version}/${fullVersion}.tar.gz.sha256sum" ]; then
			sha256=$(cat ${version}/${fullVersion}.tar.gz.sha256sum);
		else
			curl -fSL "https://github.com/changi67/itop/archive/${fullVersion}.tar.gz" -o ${fullVersion}.tar.gz
			sha256=$(sha256sum ${fullVersion}.tar.gz | awk '{print $1}')
			echo $sha256 > ${version}/${fullVersion}.tar.gz.sha256sum
			rm ${fullVersion}.tar.gz
		fi


		#for variant in fpm apache; do
		for variant in apache; do
			dist='debian'
			(
				set -x
				sed -r \
					-e 's/%%PHP_VERSION%%/'"${phpVersions[$version]:-$defaultPhpVersion}"'/' \
					-e 's/%%VARIANT%%/'"$variant"'/' \
					-e 's/%%VERSION%%/'"$fullVersion"'/' \
					-e 's/%%SHA256%%/'"$sha256"'/' \
				"./Dockerfile-$dist.template" > "$version/$variant/Dockerfile"
			)

			travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
		done
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
