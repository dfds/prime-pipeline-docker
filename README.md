# Prime Pipeline Docker Image

This project contains the dockerfile used for the Prime Pipeline Docker image.

## Requirements

To run the Docker image locally or in a build pipeline, Docker is required.

## Usage

In order to pull the image, run:

```
docker pull dfdsdk/prime-pipeline:tagname
```
Replace tagname with the release number of the release you wish to pull.
Releases can be found on [Docker Hub](https://hub.docker.com/r/dfdsdk/prime-pipeline/tags).


## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request to merge with master

Whenever a new commit is submitted to master, a build is triggered in DockerHub.
After committing, make sure to make a new incremental release in github.

## License

MIT LICENSE