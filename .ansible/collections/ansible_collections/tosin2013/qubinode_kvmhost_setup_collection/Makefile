# echo "Dont forget to update the version in galaxy.yml and README.md"
TAG=0.8.0

create-release:
	git tag -a v${TAG} -m "Creating v${TAG} release"
	git push origin v${TAG}

delete-release:
	git tag -d v${TAG}
	git push origin --delete v${TAG}
