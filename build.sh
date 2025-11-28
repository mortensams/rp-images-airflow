#!/bin/bash
# Local build script for Airflow container image

set -e

IMAGE_NAME="${IMAGE_NAME:-airflow-custom}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -n, --name NAME      Image name (default: airflow-custom)"
            echo "  -t, --tag TAG        Image tag (default: latest)"
            echo "  -r, --registry REG   Registry prefix (e.g., ghcr.io/username)"
            echo "  -p, --push           Push image after building"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build full image reference
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "Building image: ${FULL_IMAGE}"

# Build the image
docker build -t "${FULL_IMAGE}" .

echo "Build complete: ${FULL_IMAGE}"

# Push if requested
if [ "${PUSH}" = true ]; then
    echo "Pushing image: ${FULL_IMAGE}"
    docker push "${FULL_IMAGE}"
    echo "Push complete"
fi
