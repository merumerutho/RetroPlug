-- Builds the Steinberg VST3 SDK as a static library.
-- iPlug2's premake VST3 project only compiles iPlug2's own wrapper, not the SDK
-- itself, so RetroPlug links this lib to provide the VST3 SDK symbols.
-- SDK lives at thirdparty/iPlug2/Dependencies/IPlug/VST3_SDK (see download-iplug-libs.sh).

local VST3_DIR = "../thirdparty/iPlug2/Dependencies/IPlug/VST3_SDK/"

project "vst3sdk"
	kind "StaticLib"
	language "C++"

	includedirs { VST3_DIR }

	files {
		VST3_DIR .. "pluginterfaces/base/*.cpp",
		VST3_DIR .. "base/source/*.cpp",
		VST3_DIR .. "base/thread/source/*.cpp",
		VST3_DIR .. "public.sdk/source/common/*.cpp",
		VST3_DIR .. "public.sdk/source/main/*.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstaudioeffect.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstbus.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstcomponent.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstcomponentbase.cpp",
		VST3_DIR .. "public.sdk/source/vst/vsteditcontroller.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstinitiids.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstnoteexpressiontypes.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstparameters.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstpresetfile.cpp",
		VST3_DIR .. "public.sdk/source/vst/vstsinglecomponenteffect.cpp",
		-- iPlug2's VST3 processor uses the concrete ParameterChanges host class.
		VST3_DIR .. "public.sdk/source/vst/hosting/parameterchanges.cpp",
	}

	-- The common/ and main/ globs above also pick up other-platform sources.
	excludes {
		VST3_DIR .. "public.sdk/source/common/systemclipboard_linux.cpp",
		VST3_DIR .. "public.sdk/source/common/threadchecker_linux.cpp",
		VST3_DIR .. "public.sdk/source/main/linuxmain.cpp",
		VST3_DIR .. "public.sdk/source/main/macmain.cpp",
	}

	-- The VST3 SDK requires exactly one of DEVELOPMENT / RELEASE to be defined.
	configuration { "Debug" }
		defines { "DEVELOPMENT=1" }

	configuration { "Release" }
		defines { "RELEASE=1" }

	configuration { "Tracer" }
		defines { "RELEASE=1" }

	configuration { "windows" }
		defines { "_CRT_SECURE_NO_WARNINGS" }

	configuration {}
