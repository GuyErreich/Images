.PHONY: build clean

PROJECT_PATH ?= ${PWD}
PROJECT_FILE ?= $(shell cd ${PROJECT_PATH} && ls *.uproject 2>/dev/null)

clean:
	${UE_TOOLS}/RunUAT.sh BuildCookRun \
	-project="${PROJECT_PATH}/${PROJECT_FILE}" \
	-noP4 \
	-clientconfig=Development \
	-serverconfig=Development \
	-clean

build:
	${UE_TOOLS}/RunUAT.sh BuildCookRun \
	-project="${PROJECT_PATH}/${PROJECT_FILE}" \
	-noP4 \
	-clientconfig=Development \
	-serverconfig=Development \
	-cook \
	-allmaps \
	-build \
	-stage \
	-pak \
	-archive \
	-archivedirectory="${PROJECT_PATH}/Build"