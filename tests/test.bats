setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export PROJNAME=test-qdrant
  export TESTDIR=~/tmp/${PROJNAME}
  mkdir -p $TESTDIR
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev config --omit-containers="db" --disable-upload-dirs-warning >/dev/null 2>&1 || true
  ddev start -y >/dev/null
}

health_checks() {
  # Check the service is running
  echo "check qdrant service" >&3
  curl -sL https://test-qdrant.ddev.site:6333

  # Check the dashboard is running
  echo "check qdrant dashboard http statuscode" >&3
  curl -o /dev/null  -sL -w "%{http_code}\n" https://test-qdrant.ddev.site:6333/dashboard
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev stop ${PROJNAME}
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  if [ "${GITHUB_ACTIONS:-false}" != "true" ]; then
    [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
  else
    echo "Running in GitHub Actions context, skipping deletion of test data"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev restart
  health_checks
}

@test "install from main branch" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get netz98/ddev-qdrant with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get https://github.com/netz98/ddev-qdrant/tarball/main
  ddev restart >/dev/null
  health_checks
}

