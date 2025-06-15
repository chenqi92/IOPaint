#!/usr/bin/env bash
set -e

# Docker build and push script for IOPaint
# Usage: ./docker_build_push.sh [version] [platform]
# Example: ./docker_build_push.sh 1.3.5 cpu
# Example: ./docker_build_push.sh 1.3.5 gpu
# Example: ./docker_build_push.sh 1.3.5 all

DOCKER_USERNAME="kkape"
IMAGE_NAME="iopaint"

# Show help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [version] [platform]"
    echo ""
    echo "Arguments:"
    echo "  version   Docker image version (default: latest)"
    echo "  platform  Target platform: cpu, gpu, or all (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0 1.3.5 cpu    # Build CPU version only"
    echo "  $0 1.3.5 gpu    # Build GPU version only"
    echo "  $0 1.3.5 all    # Build both versions"
    echo "  $0 latest        # Build both versions with 'latest' tag"
    exit 0
fi

# Get version from argument or default
VERSION=${1:-"latest"}
PLATFORM=${2:-"all"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    log_warning "Not logged in to Docker Hub. Please run 'docker login' first."
    read -p "Do you want to continue without pushing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SKIP_PUSH=true
fi

build_and_push() {
    local dockerfile=$1
    local tag_suffix=$2
    local platform_name=$3
    
    log_info "Building ${platform_name} image..."
    
    # Build the image
    docker build \
        -f "docker/${dockerfile}" \
        --build-arg version="${VERSION}" \
        -t "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}-${tag_suffix}" \
        -t "${DOCKER_USERNAME}/${IMAGE_NAME}:${tag_suffix}" \
        .
    
    if [ $? -eq 0 ]; then
        log_success "${platform_name} image built successfully"
        
        # Push to Docker Hub if not skipping
        if [ "$SKIP_PUSH" != "true" ]; then
            log_info "Pushing ${platform_name} image to Docker Hub..."
            
            docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}-${tag_suffix}"
            docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${tag_suffix}"
            
            if [ $? -eq 0 ]; then
                log_success "${platform_name} image pushed successfully"
            else
                log_error "Failed to push ${platform_name} image"
                return 1
            fi
        else
            log_warning "Skipping push for ${platform_name} image"
        fi
    else
        log_error "Failed to build ${platform_name} image"
        return 1
    fi
}

# Main build logic
case $PLATFORM in
    "cpu")
        log_info "Building CPU-only image..."
        build_and_push "CPUDockerfile" "cpu" "CPU"
        ;;
    "gpu")
        log_info "Building GPU-enabled image..."
        build_and_push "GPUDockerfile" "gpu" "GPU"
        ;;
    "all")
        log_info "Building both CPU and GPU images..."
        build_and_push "CPUDockerfile" "cpu" "CPU"
        build_and_push "GPUDockerfile" "gpu" "GPU"
        
        # Create and push latest tag pointing to CPU version
        if [ "$SKIP_PUSH" != "true" ]; then
            log_info "Creating latest tag (pointing to CPU version)..."
            docker tag "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu" "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
            docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
            log_success "Latest tag created and pushed"
        fi
        ;;
    *)
        log_error "Invalid platform: $PLATFORM. Use 'cpu', 'gpu', or 'all'"
        exit 1
        ;;
esac

log_success "Build process completed!"

# Display usage information
echo
log_info "Docker images created:"
if [ "$PLATFORM" = "cpu" ] || [ "$PLATFORM" = "all" ]; then
    echo "  - ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu"
    echo "  - ${DOCKER_USERNAME}/${IMAGE_NAME}:cpu"
fi
if [ "$PLATFORM" = "gpu" ] || [ "$PLATFORM" = "all" ]; then
    echo "  - ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}-gpu"
    echo "  - ${DOCKER_USERNAME}/${IMAGE_NAME}:gpu"
fi
if [ "$PLATFORM" = "all" ]; then
    echo "  - ${DOCKER_USERNAME}/${IMAGE_NAME}:latest (points to CPU version)"
fi

echo
log_info "Usage examples:"
echo "  CPU version:  docker run -p 8080:8080 ${DOCKER_USERNAME}/${IMAGE_NAME}:cpu"
echo "  GPU version:  docker run --gpus all -p 8080:8080 ${DOCKER_USERNAME}/${IMAGE_NAME}:gpu"
echo "  With custom settings: docker run -p 8080:8080 -e IOPAINT_MODEL=lama -e IOPAINT_DEVICE=cpu ${DOCKER_USERNAME}/${IMAGE_NAME}:cpu"
