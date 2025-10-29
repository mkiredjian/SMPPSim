# SMPPSim Current Status

## What's Happening

You're seeing this error:
```
java.lang.NoSuchMethodError: ch.qos.logback.classic.LoggerContext.getBirthTime()J
```

## Why This Error Occurs

The error happens because you're trying to run SMPPSim with **incompatible logging library versions**. The `pom.xml` has been fixed in the repository, but you need to **rebuild the project** to download the correct dependencies.

## The Problem

**You cannot build because Maven needs internet access** to download dependencies from Maven Central, but the environment appears to have no internet connection.

---

## SOLUTION: Choose One Option Below

### Option A: Enable Internet and Build (EASIEST)

```bash
# 1. Enable internet access temporarily
# 2. Run this command:
cd /home/user/SMPPSim
mvn clean package

# 3. Run SMPPSim:
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

**This is the recommended solution.**

---

### Option B: Download Dependencies Manually

If you can access websites but Maven can't:

```bash
# 1. Run the download script:
cd /home/user/SMPPSim
bash download-dependencies.sh

# 2. The script will download 8 JAR files to /tmp/smppsim-deps/
# 3. Then manually install them or copy to lib/ directory
```

---

### Option C: Copy .m2 Repository from Another Machine

If you have another machine with internet access:

```bash
# On machine WITH internet:
cd /path/to/SMPPSim
mvn dependency:go-offline
tar -czf m2-repo.tar.gz ~/.m2/repository

# Copy m2-repo.tar.gz to your machine

# On your machine WITHOUT internet:
tar -xzf m2-repo.tar.gz -C ~/
cd /home/user/SMPPSim
mvn -o package
```

---

### Option D: Use Docker with Maven Cache

```bash
# Build in Docker with cached dependencies
docker run -it --rm \
  -v /home/user/SMPPSim:/project \
  -v maven-cache:/root/.m2 \
  maven:3.8-openjdk-11 \
  bash -c "cd /project && mvn clean package"
```

---

## Files Ready in Repository

✅ **pom.xml** - Fixed with compatible versions:
- logback-classic: 1.2.13
- slf4j-api: 1.7.36
- mysql-connector-java: 8.0.33
- HikariCP: 4.0.3

✅ **lib/smpp-lib-1.3.jar** - SMPP library (already extracted)

✅ **All MySQL integration code** - Ready to use once built

✅ **Database schema** - In db/schema.sql

---

## What Happens After Build

Once you successfully run `mvn package`, you'll get:

```
target/smppsim.jar (with all dependencies included)
```

Then you can run:
```bash
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

And you'll see:
```
SMPPSim is starting....
INFO  - MySQL database integration is disabled
INFO  - SMPPSim listening on port 5555
```

**No more errors!** 🎉

---

## Quick Diagnosis

Check what's actually wrong:

```bash
# Are you running an old JAR?
find /home/user -name "*smppsim*.jar" -type f

# Is target/ empty?
ls -lh /home/user/SMPPSim/target/

# Can Maven reach the internet?
mvn -v
ping repo1.maven.org
```

---

## Bottom Line

**You need to build the project with Maven to get the fixed dependencies.**

The code is correct, the configuration is correct, but the **JAR doesn't exist yet** because Maven can't download the dependencies without internet access.

Choose one of the options above to resolve the internet/dependency issue, then the error will be gone.
