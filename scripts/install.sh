#! /bin/bash -ex

source scripts/defaults

if [ "$BUILD_TYPE" != "tar" ]; then
    # create base directories
    mkdir -p $BUILD_DIR/usr/bin
    mkdir -p $BUILD_DIR/etc/socorro
    mkdir -p $BUILD_DIR/var/log/socorro
    mkdir -p $BUILD_DIR/var/lock/socorro
    mkdir -p $BUILD_DIR/var/run/uwsgi
    mkdir -p $BUILD_DIR/usr/lib/systemd/system/

    # Copy rc file for Socorro
    # FIXME could we replace w/ consul?
    cp scripts/crons/socorrorc $BUILD_DIR/etc/socorro/

    # Copy system configs into place
    rsync -a config/package/ $BUILD_DIR/

    # Copy in Socorro setup script
    cp scripts/setup-socorro.sh $BUILD_DIR/usr/bin

    # Update BUILD_DIR for rest of install, not package.
    BUILD_DIR=$BUILD_DIR/data/socorro
    mkdir -p $BUILD_DIR
else
    mkdir -p $BUILD_DIR/application
    rsync -a config $BUILD_DIR/application
fi

# copy to install directory
rsync -a ${VIRTUAL_ENV} $BUILD_DIR
rsync -a socorro $BUILD_DIR/application
rsync -a scripts $BUILD_DIR/application
rsync -a tools $BUILD_DIR/application
rsync -a sql $BUILD_DIR/application
rsync -a wsgi $BUILD_DIR/application
rsync -a stackwalk $BUILD_DIR/
rsync -a scripts/stackwalk.sh $BUILD_DIR/stackwalk/bin/
rsync -a analysis $BUILD_DIR/
rsync -a alembic $BUILD_DIR/application
rsync -a webapp-django $BUILD_DIR/
# because this file is served from the parent of the `webapp-django/` directory
cp contribute.json $BUILD_DIR/

if [ "$BUILD_TYPE" == "tar" ]; then
    pushd $BUILD_DIR/application/scripts/config
    for file in *.py.dist; do cp $file `basename $file .dist`; done
    popd
fi

# record current git revision in root of install dir
git rev-parse HEAD > socorro_revision.txt
cp $BUILD_DIR/stackwalk/revision.txt breakpad_revision.txt

# Write down build number, if ran by Jenkins
if [ -n "$BUILD_NUMBER" ]
then
  echo "$BUILD_NUMBER" > JENKINS_BUILD_NUMBER
else
  echo "unknown" > JENKINS_BUILD_NUMBER
fi

if [ "$BUILD_TYPE" != "tar" ]; then
    BUILD_DIR=${BUILD_DIR%%/data/socorro}
fi

# install socorro in local virtualenv
# this must run at the end to capture any generated files above
${VIRTUAL_ENV}/bin/python setup.py install
