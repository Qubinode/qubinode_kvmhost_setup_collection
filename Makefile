TAG=0.2.0

create-release:
	git tag -a v${TAG} -m "Creating v${TAG} release"
	git push origin v${TAG}

delete-release:
	git tag -d v${TAG}
	git push origin --delete v${TAG}