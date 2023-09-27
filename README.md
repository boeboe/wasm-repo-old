# WASM Plugins Server

This server provides a simple way to upload and download WASM plugin files. It is built using Go and offers a lightweight solution for managing your WASM files.
The main use case is for local development of Istio and Envoy WASM plugins.

## Features

- **Upload WASM Plugins**: Plain http upload your WASM files.
- **Download WASM Plugins**: Plain http download your uploaded WASM files with ease.
- **List All Plugins**: View a list of all uploaded WASM files.

## Prerequisites

- [Go](https://golang.org/dl/) (version 1.16 or newer)

## Getting Started

#### Clone the Repository

```console
git clone https://github.com/your-repo-link/wasm-plugins-server.git
cd wasm-plugins-server
```

#### Set Upload Directory (Optional)

By default, the server saves uploaded files to a directory named `uploads`. However, you can specify a custom directory by setting the `UPLOAD_DIR` environment variable.

```
export UPLOAD_DIR=/path/to/custom/upload/directory
```

#### Run the Server

```console
go run main.go
```

Once started, the server will be accessible at `http://localhost:8080`.

## Endpoints

These are the http endpoints available

### Uploading a WASM Plugin

> `POST /wasm-plugins/{filename}`  
Use a form field named `file` to upload the WASM file.

### Downloading a WASM Plugin
> `GET /wasm-plugins/{filename}`

### Listing All Plugins
> `GET /list`

### Example usage

```console
curl -X POST -F "file=@envoy-plugin.wasm" http://localhost:8080/wasm-plugins/envoy-plugin.wasm
curl http://localhost:8080/wasm-plugins/envoy-plugin.wasm -o envoy-plugin.wasm
```


## Deployment
### Kubernetes Deployment

Deploy the application and its necessary components using the provided Kubernetes manifest
```console
kubectl apply -f kubernetes.yaml
```

After deploying, if you've used a LoadBalancer service type, you can fetch the external IP with:
```console
kubectl get service wasm-repo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
Navigate to this IP to access the application.

For domain-based access, ensure that your domain DNS is set up to resolve wasm-repo.yourdomain.com to the external IP mentioned above. After this, you should be able to access the application using http://wasm-repo.yourdomain.com.

### Istio Deployment

Make sure the Istio Ingress Gateway is deployed in your cluster. If you've installed Istio using the default profile, the ingress gateway would already be present. Otherwise, consult the official Istio documentation to set up an Istio environment.

Deploy the application using the Istio manifest:

```console
kubectl apply -f istio.yaml
```

Once the gateway and virtual service are in place, ensure your domain DNS (wasm-repo.yourdomain.com) resolves to the IP of the Istio Ingress Gateway. You can usually retrieve this IP with:

```console
kubectl get service istio-ingressgateway -n istio-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
After setting up DNS, navigate to http://wasm-repo.yourdomain.com to access the application.

## Makefile Usage

The project includes a `Makefile` that offers a collection of commands to automate various tasks like linting, compiling, and releasing the code. Here's a breakdown of the available commands and their usage:

### Variables

- `BINARY_NAME`: The name of the compiled binary.
- `GO_FILES`: All Go source files in the project directory.
- `RELEASE_VERSION`: Version for the GitHub release and Docker image (default is `v0.1.0`).
- `DOCKER_IMAGE_NAME`: Name of the Docker image.
- `DOCKER_HUB_REPO`: Docker Hub repository where the Docker image is pushed.
- `GIT_REPO`: GitHub repository of the project.
- `UPLOAD_DIR`: Directory to save uploaded files when running the binary or Docker container.
- `LINTER`: The version of the golangci-lint tool used for linting the Go source code.

### Commands

Use the help target to get documentation
```
make help

help                           This help
lint                           Lint the project using golangci-lint (ensure it's installed)
build                          Compile the project (x86_64 & arm64)
run                            Run the binary
release                        Create a GitHub release and upload the binary
docker-build                   Build multi-platform Docker image using buildx
docker-run                     Run the Docker container
docker-release                 Release the Docker image to the registry
```

## Contributing

If you would like to contribute, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
