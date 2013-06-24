# rainbows config
Rainbows! do
	name = 'sinatratest'
	use :EventMachine
  # use :ThreadSpawn
  worker_connections 1024
  client_max_body_size nil


	# paths and things

	# Use at least one worker per core if you're on a dedicated server,
	# more will usually help for _short_ waits on databases/caches.
	worker_processes 2

	# If running the master process as root and the workers as an unprivileged
	# user, do this to switch euid/egid in the workers (also chowns logs):
	# user "unprivileged_user", "unprivileged_group"

	# tell it where to be

	# listen on both a Unix domain socket and a TCP port,
	# we use a shorter backlog for quicker failover when busy
	listen 9292
	listen "unix:/home/cesteam/workspace_ruby/CesCloudStorge/log/rainbows.sock", :backlog => 4096

	# nuke workers after 30 seconds instead of 60 seconds (the default)
	timeout 30

	# feel free to point this anywhere accessible on the filesystem
	pid "/home/cesteam/workspace_ruby/CesCloudStorge/log/rainbows.pid"

	# By default, the Unicorn logger will write to stderr.
	# Additionally, ome applications/frameworks log to stderr or stdout,
	# so prevent them from going to /dev/null when daemonized here:
	stderr_path "/home/cesteam/workspace_ruby/CesCloudStorge/log/rainbows.error.log"
	stdout_path "/home/cesteam/workspace_ruby/CesCloudStorge/log/rainbows.out.log"
	
	preload_app true

	before_fork do |server, worker|
	  # # This allows a new master process to incrementally
	  # # phase out the old master process with SIGTTOU to avoid a
	  # # thundering herd (especially in the "preload_app false" case)
	  # # when doing a transparent upgrade.  The last worker spawned
	  # # will then kill off the old master process with a SIGQUIT.
	  old_pid = "#{server.config[:pid]}.oldbin"
      if File.exists?(old_pid) && server.pid != old_pid
        begin
          Process.kill("QUIT", File.read(old_pid).to_i)
        rescue Errno::ENOENT, Errno::ESRCH
          # someone else did our job for us
        end
      end
	  #
	  # Throttle the master from forking too quickly by sleeping.  Due
	  # to the implementation of standard Unix signal handlers, this
	  # helps (but does not completely) prevent identical, repeated signals
	  # from being lost when the receiving process is busy.
	  # sleep 1
	end
end