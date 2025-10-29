#!/bin/bash
# Download all required Maven dependencies manually

echo "Downloading Maven dependencies for SMPPSim..."
echo "================================================"

# Create temporary directory
TEMP_DIR="/tmp/smppsim-deps"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Base URL
BASE_URL="https://repo1.maven.org/maven2"

# Dependencies to download
declare -A DEPS=(
    ["logback-classic"]="ch/qos/logback/logback-classic/1.2.13/logback-classic-1.2.13.jar"
    ["logback-core"]="ch/qos/logback/logback-core/1.2.13/logback-core-1.2.13.jar"
    ["slf4j-api"]="org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar"
    ["jcl-over-slf4j"]="org/slf4j/jcl-over-slf4j/1.7.36/jcl-over-slf4j-1.7.36.jar"
    ["mysql-connector"]="com/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar"
    ["HikariCP"]="com/zaxxer/HikariCP/4.0.3/HikariCP-4.0.3.jar"
    ["jakarta-regexp"]="jakarta-regexp/jakarta-regexp/1.4/jakarta-regexp-1.4.jar"
    ["junit"]="junit/junit/4.10/junit-4.10.jar"
    ["protobuf-java"]="com/google/protobuf/protobuf-java/3.21.9/protobuf-java-3.21.9.jar"
)

# Download each dependency
for name in "${!DEPS[@]}"; do
    path="${DEPS[$name]}"
    url="$BASE_URL/$path"
    filename=$(basename "$path")

    echo ""
    echo "Downloading $name..."
    echo "  URL: $url"

    if wget -q "$url" -O "$filename"; then
        echo "  ✓ Downloaded: $filename"
    elif curl -s -f -o "$filename" "$url"; then
        echo "  ✓ Downloaded: $filename"
    else
        echo "  ✗ Failed to download $filename"
        echo "  Please download manually from: $url"
    fi
done

echo ""
echo "================================================"
echo "Download complete!"
echo ""
echo "Files are in: $TEMP_DIR"
echo ""
echo "To install to Maven local repository, run:"
echo "  cd /home/user/SMPPSim"
echo "  bash install-dependencies.sh"
