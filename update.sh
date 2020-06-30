#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

defaultPhpVersion='7.4'
declare -A phpVersions=(
	[2.3]='7.1'
	[2.4]='7.1'
	[2.5]='7.2'
	[2.6]='7.3'
)

defaultMcryptVersion='1.0.3'
declare -A mcryptVersion=(
	[2.3]='1.0.0'
	[2.4]='1.0.0'
	[2.5]='1.0.1'
	[2.6]='1.0.2'
)

travisEnv=
for version in "${versions[@]}"; do

	listVersion=$(git ls-remote --tags https://github.com/Combodo/iTop/ | awk -F'/' '{print $3}' | egrep '^[0-9].[0-9].[0-9](-[0-9]+)?$')

	for fullVersion in $listVersion; do
		major=${version//./}
		minor=${fullVersion//./}
		minor=${minor//-/}
		minor=${minor::(-1)}

		if [ "${fullVersion//./}" == "242" \
			-o "${fullVersion//./}" == "240" \
			-o "${fullVersion//./}" == "241" \
			-o "${fullVersion//./}" == "243" \
			-o "${fullVersion//./}" == "250" \
			-o "${fullVersion//./}" == "251" \
			-o "${fullVersion//./}" == "252" \
			-o "${fullVersion//./}" == "253" \
			-o "${fullVersion//./}" == "254" \
			-o "${fullVersion//./}" == "260" \
			-o "${fullVersion//./}" == "262" \
			-o "${fullVersion//./}" == "262-1" \
			-o "${fullVersion//./}" == "262-2" \
			]; then
			continue;
		fi

		if [ "$minor" -gt "100" ]; then
			minor=${minor::(-1)}
		fi

		if [ "$major" -ne "$minor" ]; then
			echo "$fullVersion not compatible with current version $version";
			continue;
		fi

		link="https://github.com/Combodo/iTop/archive/$fullVersion.zip"
		if [ -f "${version}/${fullVersion}.zip.sha256sum" ]; then
			sha256=$(cat ${version}/${fullVersion}.zip.sha256sum);
		else
			curl -fsSL $link -o ${fullVersion}.zip
			sha256=$(sha256sum ${fullVersion}.zip | awk '{print $1}')
			echo $sha256 > ${version}/${fullVersion}.zip.sha256sum
			rm ${fullVersion}.zip
		fi


		#for variant in fpm apache; do
		for variant in apache; do
			if ! [ -d "$variant" ]; then
				mkdir -p $version/$variant
			fi
			dist='debian'
			if [ "$minor" -gt "26"  ]; then
				template="Dockerfile-$dist.php74.template"
			else
				template="Dockerfile-$dist.template"
			fi
			(
				set -x
				sed -r \
					-e 's/%%PHP_VERSION%%/'"${phpVersions[$version]:-$defaultPhpVersion}"'/' \
					-e 's/%%MCRYPT_VERSION%%/'"${mcryptVersion[$version]:-$defaultMcryptVersion}"'/' \
					-e 's/%%VARIANT%%/'"$variant"'/' \
					-e 's/%%VERSION%%/'"$fullVersion"'/' \
					-e 's/%%SHA256%%/'"$sha256"'/' \
				"./$template" > "$version/$variant/Dockerfile"
			)

			travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
		done
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
