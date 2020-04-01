IF (BUILT_CRYPTO)
	SET (BUILT_CRYPTO ${BUILT_CRYPTO} CACHE BOOL "Remeber that cryptopp was built" FORCE)

	EXTERNALPROJECT_ADD (CRYPTO
		GIT_REPOSITORY https://github.com/weidai11/cryptopp.git
		GIT_TAG CRYPTOPP_8_2_0
		GIT_PROGRESS TRUE
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND ""
	)

	EXTERNALPROJECT_GET_PROPERTY (CRYPTO SOURCE_DIR TMP_DIR)

	IF (WIN32)
		FILE (MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/cryptopp)
		FILE (MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
		FILE (GLOB COPY_HEADERS LIST_DIRECTORIES FALSE ${SOURCE_DIR}/*.h)
		FOREACH (HEADER ${COPY_HEADERS})
			CONFIGURE_FILE (${HEADER} ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/cryptopp/ COPYONLY)
		ENDFOREACH (HEADER ${COPY_HEADERS})
		CONFIGURE_FILE (${SOURCE_DIR}/Win32/DLL_Output/Release/cryptopp.dll ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/ COPYONLY)
		CONFIGURE_FILE (${SOURCE_DIR}/Win32/DLL_Output/Release/cryptopp.lib ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/ COPYONLY)
		CONFIGURE_FILE (${SOURCE_DIR}/Win32/DLL_Output/Release/cryptopp.dll ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cryptoppd.dll COPYONLY)
		CONFIGURE_FILE (${SOURCE_DIR}/Win32/DLL_Output/Release/cryptopp.lib ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cryptoppd.lib COPYONLY)
		SET (CRYPTOPP_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}  CACHE PATH "Search hint for crypto++ headers" FORCE)
		SET (CRYPTOPP_LIB_SEARCH_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/ CACHE PATH "Search hint for crypto++ library" FORCE)
	ELSE (WIN32)
		SET (CRYPTOPP_INCLUDE_DIR ${TMP_DIR}/include/ CACHE PATH "Search hint for crypto++ headers" FORCE)
		SET (CRYPTOPP_LIB_SEARCH_PATH ${TMP_DIR}/lib CACHE PATH "Search hint for crypto++ library" FORCE)
	ENDIF (WIN32)

	SET (CMAKE_REQUIRED_INCLUDES ${CRYPTOPP_INCLUDE_DIR})

	INSTALL (
		CODE ${CMAKE_MAKE_PROGRAM} -f ${SOURCE_DIR}/GNUmakefile install-lib
	)
ENDIF (BUILT_CRYPTO)

IF (NOT CRYPTOPP_CONFIG_FILE)
	SET (CRYPTOPP_SEARCH_PREFIXES "cryptopp" "crypto++")

	IF (NOT CRYPTOPP_INCLUDE_PREFIX)
		UNSET (CRYPT_SEARCH CACHE)
		CHECK_INCLUDE_FILE_CXX (cryptlib.h CRYPT_SEARCH)

		IF (CRYPT_SEARCH)
			SET (CRYPTOPP_INCLUDE_PREFIX "" CACHE STRING "cryptopp include prefix" FORCE)
		ELSE (CRYPT_SEARCH)
			FOREACH (PREFIX ${CRYPTOPP_SEARCH_PREFIXES})
				UNSET (CRYPT_SEARCH CACHE)
				CHECK_INCLUDE_FILE_CXX (${PREFIX}/cryptlib.h CRYPT_SEARCH)

				IF (CRYPT_SEARCH)
					MESSAGE (STATUS "cryptopp prefix found: ${PREFIX}")
					SET (CRYPTOPP_INCLUDE_PREFIX ${PREFIX} CACHE STRING "cryptopp include prefix" FORCE)
					BREAK()
				ENDIF (CRYPT_SEARCH)
			ENDFOREACH (PREFIX CRYPTOPP_SEARCH_PREFIXES)
		ENDIF (CRYPT_SEARCH)
	ENDIF (NOT CRYPTOPP_INCLUDE_PREFIX)

	IF (NOT CRYPTOPP_INCLUDE_PREFIX)
		IF (NOT DOWNLOAD_AND_BUILD_DEPS AND NOT BUILT_CRYPTO)
			MESSAGE (FATAL_ERROR "cryptlib.h not found")
		ELSE (NOT DOWNLOAD_AND_BUILD_DEPS AND NOT BUILT_CRYPTO)
			MESSAGE (STATUS "cryptlib.h not found - will be built")
		ENDIF (NOT DOWNLOAD_AND_BUILD_DEPS AND NOT BUILT_CRYPTO)
	ENDIF (NOT CRYPTOPP_INCLUDE_PREFIX)

	IF (WIN32)
		UNSET (CRYPTOPP_LIBRARY_DEBUG)
		UNSET (CRYPTOPP_LIBRARY_RELEASE)
		FIND_LIBRARY (CRYPTOPP_LIBRARY_DEBUG
			NAMES crypto++d cryptlibd cryptoppd
			PATHS ${CRYPTOPP_LIB_SEARCH_PATH}
		)

		FIND_LIBRARY (CRYPTOPP_LIBRARY_RELEASE
			NAMES crypto++ cryptlib cryptopp
			PATHS ${CRYPTOPP_LIB_SEARCH_PATH}
		)
	ELSE (WIN32)
		UNSET (CRYPTOPP_LIBRARY)
		FIND_LIBRARY (CRYPTOPP_LIBRARY
			NAMES crypto++ cryptlib cryptopp
			PATHS ${CRYPTOPP_LIB_SEARCH_PATH}
	)
	ENDIF (WIN32)

	IF (CRYPTOPP_LIBRARY)
		MESSAGE (STATUS "Found libcrypto++ in ${CRYPTOPP_LIBRARY}")
	ENDIF (CRYPTOPP_LIBRARY)

	UNSET (CRYPTOPP_CONFIG_SEARCH CACHE)
	CHECK_INCLUDE_FILE_CXX (${CRYPTOPP_INCLUDE_PREFIX}/config.h CRYPTOPP_CONFIG_SEARCH)

	IF (CRYPTOPP_CONFIG_SEARCH)
		IF (CRYPTOPP_INCLUDE_DIR)
			SET (CRYPTOPP_CONFIG_FILE ${CRYPTOPP_INCLUDE_DIR}/${CRYPTOPP_INCLUDE_PREFIX}/config.h CACHE FILEPATH "cryptopp config.h" FORCE)
		ELSE (CRYPTOPP_INCLUDE_DIR)
			SET (CRYPTOPP_CONFIG_FILE ${CRYPTOPP_INCLUDE_PREFIX}/config.h CACHE FILEPATH "cryptopp config.h" FORCE)
		ENDIF (CRYPTOPP_INCLUDE_DIR)
	ELSE (CRYPTOPP_CONFIG_SEARCH)
		UNSET (CRYPTOPP_CONFIG_SEARCH)
	ENDIF (CRYPTOPP_CONFIG_SEARCH)

	UNSET (CMAKE_REQUIRED_INCLUDES)

	IF (NOT CRYPTOPP_CONFIG_FILE)
		IF (DOWNLOAD_AND_BUILD_DEPS)
			MESSAGE (STATUS "crypto++ config.h not found - will be built")
		ELSE (DOWNLOAD_AND_BUILD_DEPS)
			MESSAGE (FATAL_ERROR "crypto++ config.h not found")
		ENDIF (DOWNLOAD_AND_BUILD_DEPS)
	ENDIF (NOT CRYPTOPP_CONFIG_FILE)

	IF (CRYPTOPP_CONFIG_FILE)
		SET (CMAKE_CONFIGURABLE_FILE_CONTENT
			"#include <${CRYPTOPP_CONFIG_FILE}>\n
			#include <stdio.h>\n
			int main(){\n
				printf (\"%d\", CRYPTOPP_VERSION);\n
			}\n"
		)

		CONFIGURE_FILE ("${CMAKE_ROOT}/Modules/CMakeConfigurableFile.in"
			"${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/CheckCryptoppVersion.cxx" @ONLY IMMEDIATE
		)

		TRY_RUN (RUNRESULT
			COMPILERESULT
			${CMAKE_BINARY_DIR}
			${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/CheckCryptoppVersion.cxx
			RUN_OUTPUT_VARIABLE CRYPTOPP_VERSION
		)

		STRING (REGEX REPLACE "([0-9])([0-9])([0-9])" "\\1.\\2.\\3" CRYPTOPP_VERSION "${CRYPTOPP_VERSION}")

		IF (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
			MESSAGE (FATAL_ERROR "crypto++ version ${CRYPTOPP_VERSION} is too old")
		ELSE (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
			MESSAGE (STATUS "crypto++ version ${CRYPTOPP_VERSION} -- OK")
			SET (CRYPTOPP_CONFIG_FILE ${CRYPTOPP_CONFIG_FILE} CACHE STRING "Path to config.h of crypto-lib" FORCE)
		ENDIF (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
	ENDIF (CRYPTOPP_CONFIG_FILE)
ENDIF (NOT CRYPTOPP_CONFIG_FILE)

IF (DOWNLOAD_AND_BUILD_DEPS AND NOT CRYPTOPP_CONFIG_FILE AND NOT BUILT_CRYPTO)
	IF (WIN32)
		EXTERNALPROJECT_ADD (CRYPTO
			GIT_REPOSITORY https://github.com/weidai11/cryptopp.git
			GIT_TAG CRYPTOPP_8_2_0
			GIT_PROGRESS TRUE
			CONFIGURE_COMMAND SET _CL_=/MD && ${CMAKE_MAKE_PROGRAM} cryptdll.vcxproj -p:Configuration=Release
			BUILD_IN_SOURCE TRUE
			BUILD_COMMAND SET _CL_=/MD && ${CMAKE_MAKE_PROGRAM} cryptdll.vcxproj -p:Configuration=Debug
			INSTALL_COMMAND ""
		)
	ELSE (WIN32)
		EXTERNALPROJECT_ADD (CRYPTO
			GIT_REPOSITORY https://github.com/weidai11/cryptopp.git
			GIT_TAG CRYPTOPP_8_2_0
			GIT_PROGRESS TRUE
			CONFIGURE_COMMAND ${CMAKE_MAKE_PROGRAM} -f GNUmakefile shared
			BUILD_IN_SOURCE TRUE
			BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} -f GNUmakefile install-lib PREFIX=<TMP_DIR>
			INSTALL_COMMAND ""
		)
	ENDIF(WIN32)

	LIST (APPEND EXTERNAL_DEPS CRYPTO)
	SET (RECONF_COMMAND ${RECONF_COMMAND} -DBUILT_CRYPTO=TRUE)
ENDIF (DOWNLOAD_AND_BUILD_DEPS AND NOT CRYPTOPP_CONFIG_FILE AND NOT BUILT_CRYPTO)