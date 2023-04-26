#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libcgroup.h>
#include <sys/syscall.h>

/*
 * Assumes cgroup is mounted at /cgroup using
 *
 * mount -t cgroup -o none,name=test none /cgroup
 * gcc a.c -o cgroup -lcgroup
 */
int main()
{
	int ret;
	struct cgroup *cgroup;
	struct cgroup_controller *cgc;

	ret = cgroup_init();
	if (ret) {
		printf("FAIL: cgroup_init failed with %s\n", cgroup_strerror(ret));
		exit(3);
	}

	cgroup = cgroup_new_cgroup("/mysql/donatas4");
	if (!cgroup) {
		printf("FAIL: cgroup_new_cgroup failed\n");
		exit(3);
	}

	cgc = cgroup_add_controller(cgroup, "cpu");
	if (!cgc) {
		printf("FAIL: cgroup_add_controller failed\n");
		exit(3);
	}

    ret = cgroup_set_uid_gid(cgroup, 1000, 1000, 1000, 1000);
    if (ret) {
		printf("FAIL: cgroup_set_uid_gid failed with %s\n", cgroup_strerror(ret));
    }

	ret = cgroup_create_cgroup(cgroup, 1);
	if (ret) {
		printf("FAIL: cgroup_create_cgroup failed with %s\n", cgroup_strerror(ret));
		exit(3);
	}

	if (access("/sys/fs/cgroup/cpu/mysql/donatas/tasks", F_OK) == 0)
		printf("PASS\n");
	else
		printf("Failed to create cgroup\n");

    pid_t tid = syscall(SYS_gettid);
    ret = cgroup_attach_task_pid(cgroup, tid);
    printf("attach task: %d\n", tid);

	return 0;
}

