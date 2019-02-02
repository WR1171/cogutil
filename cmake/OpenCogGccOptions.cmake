# ===============================================================
# Detect different compilers and OS'es, tweak flags as necessary.

IF (CMAKE_COMPILER_IS_GNUCXX)
	# version 5.0 of gcc is required for passing non-trivially
	# copyable class via C varargs

	IF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.0)
		MESSAGE(FATAL_ERROR "GCC version must be at least 5.0!")
	ENDIF (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.0)

	IF (APPLE)
		CMAKE_POLICY(SET CMP0042 NEW)  # Something about MACOSX_RPATH

		SET(CMAKE_C_FLAGS "-Wall -Wno-long-long -Wno-conversion")
		SET(CMAKE_C_FLAGS_DEBUG "-O0 -g")
		SET(CMAKE_C_FLAGS_PROFILE "-O0 -pg")
		SET(CMAKE_C_FLAGS_RELEASE "-O2 -g0")
		# Vital to do this otherwise unresolved symbols everywhere:
		SET(CMAKE_SHARED_LINKER_FLAGS "-Wl,-flat_namespace,-undefined,dynamic_lookup")
		SET(CMAKE_EXE_LINKER_FLAGS "-Wl,-flat_namespace,-undefined,dynamic_lookup")

		# The Apple linker does not support the --no-as-needed flag.
		SET(NO_AS_NEEDED "")

	ELSE (APPLE)
		SET(CMAKE_C_FLAGS "-Wall -fPIC")
		# SET(CMAKE_C_FLAGS "-Wl,--copy-dt-needed-entries")
		SET(CMAKE_C_FLAGS_DEBUG "-O0 -ggdb3 -fstack-protector")
		SET(CMAKE_C_FLAGS_PROFILE "-O2 -g3 -fstack-protector -pg")
		# -flto is good for performance, but wow is it slow to link...
		# XXX disable for now ... its just to painful, in daily life.
		# ... except that the buildbot needs this, to pass unit tests.
		# Current failure is in libatomcore, which depends on atomutils
		# (ldd -r libatomcore.so shows unresolved symbols.)
		SET(CMAKE_C_FLAGS_RELEASE "-O3 -g -fstack-protector")
		# SET(CMAKE_C_FLAGS_RELEASE "-O3 -g -fstack-protector -flto")
		# SET(CMAKE_C_FLAGS_RELEASE "-O3 -g -fstack-protector -flto=8")

		SET(NO_AS_NEEDED "-Wl,--no-as-needed")
		LINK_LIBRARIES(pthread)

		# Workaround for circular dependencies problem. This causes
		# LINK_LIBRARIES to appear twice in the linker line; the
		# second appearance has the effect of resolving any circular
		# dependencies left over from the first specification.
		# See pull request #642 for more discussion.
		SET(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_CXX_LINK_EXECUTABLE} <LINK_LIBRARIES>")
	ENDIF (APPLE)

	# 1) -Wno-variadic-macros is to avoid warnings regarding using
	# variadic in macro OC_ASSERT (the warning warns that this is only
	# available from C99, lol!)
	#
	# 2) -fopenmp for multithreading support
	#
	# 3) -std=gnu++11 for C++11 and GNU extensions support
	SET(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -Wno-variadic-macros -fopenmp -std=gnu++11")

	SET(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})
	SET(CMAKE_CXX_FLAGS_PROFILE ${CMAKE_C_FLAGS_PROFILE})
	SET(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})

	# Options for generating gcov code coverage output
	SET(CMAKE_C_FLAGS_COVERAGE "-O0 -g -fprofile-arcs -ftest-coverage -fno-inline")
	SET(CMAKE_CXX_FLAGS_COVERAGE "${CMAKE_C_FLAGS_COVERAGE} -fno-default-inline")
	# Might be needed for some combinations of ln and gcc
	IF (CMAKE_BUILD_TYPE STREQUAL "Coverage")
		LINK_LIBRARIES(gcov)
	ENDIF (CMAKE_BUILD_TYPE STREQUAL "Coverage")
ENDIF (CMAKE_COMPILER_IS_GNUCXX)