worker_processes 2
working_directory "/srv/students/"

preload_app true
timeout 300
listen "0.0.0.0:8085", :backlog => 64
pid "/var/run/unicorn/unicorn-new-students.pid"
stderr_path "/var/log/unicorn/new-students.stderr.log"
stdout_path "/var/log/unicorn/new-students.stdout.log"
