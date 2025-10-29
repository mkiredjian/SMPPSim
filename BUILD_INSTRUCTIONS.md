# SMPPSim Build Instructions

## Current Issue

You're getting `NoSuchMethodError` because the project hasn't been built with the updated dependencies yet. The fixed `pom.xml` is in the repository, but Maven needs internet access to download the dependencies.

---

## Solution 1: Build with Internet Access (Recommended)

### Enable internet temporarily and run:

```bash
cd /home/user/SMPPSim

# Download all dependencies and build
mvn clean package -DskipTests
```

This will download:
- logback-classic 1.2.13
- logback-core 1.2.13 (transitive)
- slf4j-api 1.7.36
- jcl-over-slf4j 1.7.36
- mysql-connector-java 8.0.33
- HikariCP 4.0.3
- jakarta-regexp 1.4
- junit 4.10

The final JAR will be: `target/smppsim.jar`

---

## Solution 2: Use Pre-Built JAR (If Available)

If you have a previously built JAR from another environment:

```bash
# Copy the JAR to target directory
mkdir -p /home/user/SMPPSim/target
cp /path/to/smppsim.jar /home/user/SMPPSim/target/

# Run it
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

---

## Solution 3: Manual Dependency Installation

If you can download files individually but not use Maven Central directly:

### Required JAR Files:

1. **logback-classic-1.2.13.jar**
   - URL: https://repo1.maven.org/maven2/ch/qos/logback/logback-classic/1.2.13/logback-classic-1.2.13.jar

2. **logback-core-1.2.13.jar**
   - URL: https://repo1.maven.org/maven2/ch/qos/logback/logback-core/1.2.13/logback-core-1.2.13.jar

3. **slf4j-api-1.7.36.jar**
   - URL: https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar

4. **jcl-over-slf4j-1.7.36.jar**
   - URL: https://repo1.maven.org/maven2/org/slf4j/jcl-over-slf4j/1.7.36/jcl-over-slf4j-1.7.36.jar

5. **mysql-connector-java-8.0.33.jar**
   - URL: https://repo1.maven.org/maven2/com/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar

6. **HikariCP-4.0.3.jar**
   - URL: https://repo1.maven.org/maven2/com/zaxxer/HikariCP/4.0.3/HikariCP-4.0.3.jar

7. **jakarta-regexp-1.4.jar**
   - URL: https://repo1.maven.org/maven2/jakarta-regexp/jakarta-regexp/1.4/jakarta-regexp-1.4.jar

8. **junit-4.10.jar**
   - URL: https://repo1.maven.org/maven2/junit/junit/4.10/junit-4.10.jar

### Install to Local Maven Repository:

```bash
# Create directory structure
mkdir -p ~/.m2/repository

# Install each JAR (example for logback-classic)
mvn install:install-file \
  -Dfile=/path/to/logback-classic-1.2.13.jar \
  -DgroupId=ch.qos.logback \
  -DartifactId=logback-classic \
  -Dversion=1.2.13 \
  -Dpackaging=jar

# Repeat for each dependency...
```

Then build offline:
```bash
mvn -o package
```

---

## Solution 4: Run Without Building (For Testing Configuration)

If you just want to test the configuration changes without building:

1. Check if there's an existing working JAR in another location
2. Update its classpath to use new logback versions
3. Run with explicit classpath:

```bash
java -cp "lib/*:old-smppsim.jar" \
  com.seleniumsoftware.SMPPSim.SMPPSim \
  conf/logback.xml conf/smppsim.props
```

---

## Verifying the Fix

Once built successfully, you should see:

```
SMPPSim is starting....
INFO  - ==============================================================
INFO  - =  SMPPSim Copyright (C) 2006 Selenium Software Ltd
INFO  - =  SMPPSim comes with ABSOLUTELY NO WARRANTY
...
INFO  - =  SMPP_PORT                               :5555
INFO  - =  MySQL database integration is disabled
INFO  - ==============================================================
INFO  - SMPPSim ready to accept connections on port 5555
```

**No more `NoSuchMethodError`!**

---

## Troubleshooting

### "Still getting NoSuchMethodError"

This means you're running an old JAR. Check:

```bash
# Find all smppsim JARs
find ~ -name "*smppsim*.jar" -ls

# Check what JAR you're actually running
ps aux | grep smppsim
```

### "Cannot download dependencies"

Options:
1. Use a Maven proxy/mirror that you can access
2. Download JARs manually (see Solution 3)
3. Copy ~/.m2/repository from another machine that can access Maven Central

### "Build succeeds but error persists"

You may be running the wrong JAR:

```bash
# Make sure you're running the newly built JAR
ls -lh target/smppsim.jar

# Run explicitly
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

---

## Quick Start (With Internet)

```bash
cd /home/user/SMPPSim
mvn clean package
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

That's it! The application should start without errors.
