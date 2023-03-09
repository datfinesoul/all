To use these commands, update your SAM template to specify the path
to your function's source code in the resource's Code or CodeUri property.

To build on your workstation, run this command in the directory containing your
SAM template. Built artifacts are written to the .aws-sam/build directory.
$ sam build
 
To build inside a Lambda-like Docker container
$ sam build --use-container

To build with environment variables passed to the build container from the command line
$ sam build --use-container --container-env-var Function1.GITHUB_TOKEN=<token1> --container-env-var GLOBAL_ENV_VAR=<global-token>

To build with environment variables passed to the build container from a file
$ sam build --use-container --container-env-var-file <env-file.json>

Build a Node.js 12 application using a container image pulled from DockerHub
$ sam build --use-container --build-image amazon/aws-sam-cli-build-image-nodejs12.x

Build a function resource using the Python 3.8 container image pulled from DockerHub
$ sam build --use-container --build-image Function1=amazon/aws-sam-cli-build-image-python3.8 
  
To build and run your functions locally
$ sam build && sam local invoke
  
To build and package for deployment
$ sam build && sam package --s3-bucket <bucketname>

To build the 'MyFunction' resource
$ sam build MyFunction

To build the 'MyFunction' resource of the 'MyNestedStack' nested stack
$ sam build MyNestedStack/MyFunction
