EnsureSConsVersion(0,14)

import string
import os
import os.path
import glob
import sys
import methods

# # Enable aggresive compile mode if building on a multi core box
# # only is we have not set the number of jobs already or we do
# # not want it
# if ARGUMENTS.get('spawn_jobs', 'no') == 'yes' and int(GetOption('num_jobs')) <= 1:
# 	import multiprocessing
# 	NUM_JOBS = multiprocessing.cpu_count()
# 	if NUM_JOBS > 1:
# 		SetOption('num_jobs', NUM_JOBS+1)

methods.update_version()

# scan possible build platforms

platform_list = [] # list of platforms
platform_opts = {} # options for each platform
platform_flags = {} # flags for each platform

active_platforms = []
active_platform_ids = []

for x in glob.glob("platform/*"):
	if (not os.path.isdir(x) or not os.path.exists(x+"/detect.py")):
		continue
	tmppath="./"+x

	sys.path.append(tmppath)
	import detect

	if (detect.is_active()):
		active_platforms.append(detect.get_name())
		active_platform_ids.append(x)
	if (detect.can_build()):
		x=x.replace("platform/","") # rest of world
		x=x.replace("platform\\","") # win32
		platform_list+=[x]
		platform_opts[x]=detect.get_opts()
		platform_flags[x]=detect.get_flags()
	sys.path.remove(tmppath)
	sys.modules.pop('detect')

module_list = methods.detect_modules()

print "Detected Platforms: "+str(platform_list)

# methods.save_active_platforms(active_platforms,active_platform_ids)

custom_tools=['default']

platform_arg = ARGUMENTS.get("platform", False)

if (os.name=="posix"):
	pass
elif (os.name=="nt"):
	if (os.getenv("VSINSTALLDIR")==None or platform_arg=="android"):
		custom_tools=['mingw']

env_base=Environment(tools=custom_tools)
env_base.AppendENVPath('PATH', os.getenv('PATH'))
env_base.AppendENVPath('PKG_CONFIG_PATH', os.getenv('PKG_CONFIG_PATH'))


env_base.disabled_modules=[""]
env_base.__class__.disable_module = methods.disable_module

env_base.__class__.add_source_files = methods.add_source_files

env_base.__class__.use_windows_spawn_fix = methods.use_windows_spawn_fix

env_base["x86_opt_gcc"]=False
env_base["x86_opt_vc"]=False
env_base["armv7_opt_gcc"]=False

customs = ['custom.py']

profile = ARGUMENTS.get("profile", False)
if profile:
	import os.path
	if os.path.isfile(profile):
		customs.append(profile)
	elif os.path.isfile(profile+".py"):
		customs.append(profile+".py")

opts=Variables(customs, ARGUMENTS)
opts.Add('target', 'Compile Target (debug/release_debug/release).', "debug")
opts.Add('bits', 'Compile Target Bits (default/32/64/fat).', "default")
opts.Add('platform','Platform: '+str(platform_list)+'.',"")
opts.Add('p','Platform (same as platform=).',"")
opts.Add('tools','Build Tools (Including Editor): (yes/no)','yes')
opts.Add('vsproj', 'Generate Visual Studio Project. (yes/no)', 'no')

# add platform specific options
for k in platform_opts.keys():
	opt_list = platform_opts[k]
	for o in opt_list:
		opts.Add(o[0],o[1],o[2])

for x in module_list:
	opts.Add('module_'+x+'_enabled', "Enable module '"+x+"'.", "yes")

opts.Update(env_base) # update environment
Help(opts.GenerateHelpText(env_base)) # generate help

# add default include paths
env_base.Append(CPPPATH=['#source','#3rd','#3rd/lua/src','#'])

# if (env_base['target']=='debug'):
# 	env_base.Append(CPPFLAGS=['-DDEBUG_MEMORY_ALLOC'])
# 	env_base.Append(CPPFLAGS=['-DSCI_NAMESPACE'])

env_base.platforms = {}

selected_platform =""

if env_base['platform'] != "":
	selected_platform = env_base['platform']
elif env_base['p'] != "":
	selected_platform = env_base['p']
	env_base["platform"] = selected_platform

if selected_platform in platform_list:

	sys.path.append("./platform/"+selected_platform)
	import detect
	if "create" in dir(detect):
		env = detect.create(env_base)
	else:
		env = env_base.Clone()

	if env['vsproj']=="yes":
		env.vs_incs = []
		env.vs_srcs = []

		def AddToVSProject(sources):
			for x in sources:
				if type(x) == type(""):
					fname = env.File(x).path
				else:
					fname = env.File(x)[0].path
				pieces =  fname.split(".")
				if len(pieces)>0:
					basename = pieces[0]
					basename = basename.replace('\\\\','/')
					env.vs_srcs = env.vs_srcs + [basename + ".cpp"]
					env.vs_incs = env.vs_incs + [basename + ".h"]
					#print basename
		env.AddToVSProject = AddToVSProject

	env.extra_suffix=""

	if env.extra_suffix != '' :
		env.extra_suffix += '.'+env["extra_suffix"]

	CCFLAGS = env.get('CCFLAGS', '')
	env['CCFLAGS'] = ''

	env.Append(CCFLAGS=string.split(str(CCFLAGS)))

	CFLAGS = env.get('CFLAGS', '')
	env['CFLAGS'] = ''

	env.Append(CFLAGS=string.split(str(CFLAGS)))

	LINKFLAGS = env.get('LINKFLAGS', '')
	env['LINKFLAGS'] = ''

	env.Append(LINKFLAGS=string.split(str(LINKFLAGS)))

	flag_list = platform_flags[selected_platform]
	for f in flag_list:
		if not (f[0] in ARGUMENTS): # allow command line to override platform flags
			env[f[0]] = f[1]

	#must happen after the flags, so when flags are used by configure, stuff happens (ie, ssl on x11)
	detect.configure(env)


# 	if (env["freetype"]!="no"):
# 		env.Append(CCFLAGS=['-DFREETYPE_ENABLED'])
# 		if (env["freetype"]=="builtin"):
# 			env.Append(CPPPATH=['#drivers/freetype'])
# 			env.Append(CPPPATH=['#drivers/freetype/freetype/include'])


	#env['platform_libsuffix'] = env['LIBSUFFIX']

	suffix="."+selected_platform

	if (env["target"]=="release"):
# 		if (env["tools"]=="yes"):
# 			print("Tools can only be built with targets 'debug' and 'release_debug'.")
# 			sys.exit(255)
		suffix+=".opt"

	elif (env["target"]=="release_debug"):
		if (env["tools"]=="yes"):
			suffix+=".opt.tools"
		else:
			suffix+=".opt.debug"
	else:
		if (env["tools"]=="yes"):
			suffix+=".tools"
		else:
			suffix+=".debug"

	if (env["bits"]=="32"):
		suffix+=".32"
	elif (env["bits"]=="64"):
		suffix+=".64"
	elif (env["bits"]=="fat"):
		suffix+=".fat"

	suffix+=env.extra_suffix

	# env["PROGSUFFIX"] = suffix + env["PROGSUFFIX"]
	# env["OBJSUFFIX"] = suffix + env["OBJSUFFIX"]
	# env["LIBSUFFIX"] = suffix + env["LIBSUFFIX"]
	# env["SHLIBSUFFIX"] = suffix + env["SHLIBSUFFIX"]

	sys.path.remove("./platform/"+selected_platform)
	sys.modules.pop('detect')

	env.module_list=[]

	for x in module_list:
		if env['module_'+x+'_enabled'] != "yes":
			continue
		tmppath="./modules/"+x
		sys.path.append(tmppath)
		env.current_module=x
		import config
		if (config.can_build(selected_platform)):
			config.configure(env)
			env.module_list.append(x)
		sys.path.remove(tmppath)
		sys.modules.pop('config')

# 	if (env['lua']=='yes'):
# 		env.Append(CPPFLAGS=['-DLUASCRIPT_ENABLED'])

	Export('env')
	#build subdirs, the build order is dependent on link order.
	SConscript("3rd/SCsub")
	SConscript("source/SCsub")
# 	SConscript("platform/"+selected_platform+"/SCsub") # build selected platform

else:

	print("No valid target platform selected.")
	print("The following were detected:")
	for x in platform_list:
		print("\t"+x)
	print("\nPlease run scons again with argument: platform=<string>")
