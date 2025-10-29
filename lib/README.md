# SMPPSim Library Directory

This directory contains the SMPP library JAR that is not available in Maven Central.

## smpp-lib-1.3.jar

**Source**: Extracted from `conf/smpp-lib.zip`
**Purpose**: SMPP protocol implementation library
**Version**: 1.3

This library is referenced in `pom.xml` using system scope:

```xml
<dependency>
    <groupId>smpp</groupId>
    <artifactId>smpp-lib</artifactId>
    <version>1.3</version>
    <scope>system</scope>
    <systemPath>${project.basedir}/lib/smpp-lib-1.3.jar</systemPath>
</dependency>
```

## Installation

The JAR is already extracted and ready to use. When you run `mvn package`, Maven will automatically include this library in the final JAR.

## Alternative: Install to Local Maven Repository

If you prefer to install it to your local Maven repository instead of using system scope:

```bash
mvn install:install-file \
  -Dfile=lib/smpp-lib-1.3.jar \
  -DgroupId=smpp \
  -DartifactId=smpp-lib \
  -Dversion=1.3 \
  -Dpackaging=jar
```

Then update `pom.xml` to remove the `<scope>system</scope>` and `<systemPath>` lines.
