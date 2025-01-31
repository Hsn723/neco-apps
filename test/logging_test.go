package test

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	corev1 "k8s.io/api/core/v1"
)

func testLogging() {
	It("should get some patterns logs from logging system", func() {
		checkLog("should get pod logs", `'{namespace="logging"}'`) // get logs from all pods

		ssNodeName := getNodeName("ss")
		checkLog("should get journal logs from ss", fmt.Sprintf(`'{job="systemd-journal", instance="%s"}'`, ssNodeName))

		csNodeName := getNodeName("cs")
		checkLog("should get journal logs from cs", fmt.Sprintf(`'{job="systemd-journal", instance="%s"}'`, csNodeName))

		stdout, _, err := ExecAt(boot0, "hostname")
		Expect(err).ShouldNot(HaveOccurred())
		bootServerName := strings.TrimSpace(string(stdout))
		checkLog("should get journal logs from boot", fmt.Sprintf(`'{job="systemd-journal", hostname="%s"}'`, bootServerName))

		masterNodeName := getNodeName("master")
		checkLog("should get audit logs from master", fmt.Sprintf(`'{job="kubernetes-apiservers", type="audit", instance="%s"}'`, masterNodeName))
	})

	It("should get logs from logging-small", func() {
		checkLogSmall("should get pod logs", `'{namespace="ceph-object-store"}'`) // get logs from all pods

		checkLogSmall("should get journal logs from ss", `'{syslog_identifier="kernel", hostname=~".*-ss.*"}'`)

		checkLogSmall("should get journal logs from cs", `'{syslog_identifier="kernel", hostname=~".*-cs.*"}'`)
	})

	It("should export ceph-rgw request duration seconds", func() {
		query := `histogram_quantile(0.95, sum(rate(ceph_rgw_request_duration_seconds_bucket{}[5m])) by (le, pod, namespace, http_status, method))`
		Eventually(func() error {
			result, err := queryMetrics(MonitoringLargeset, query)
			if err != nil {
				return err
			}
			if len(result.Data.Result) <= 0 {
				return fmt.Errorf("no count metrics is retrieved")
			}
			return nil
		}).ShouldNot(HaveOccurred())
	})
}

func checkLogCommon(title string, f func() ([]byte, []byte, error)) {
	By(title, func() {
		Eventually(func() error {
			stdout, stderr, err := f()
			if err != nil {
				return fmt.Errorf("stdout: %s, stderr: %s, err: %v", stdout, stderr, err)
			}

			scanner := bufio.NewScanner(bytes.NewBuffer(stdout))
			hasLog := false
			for scanner.Scan() {
				hasLog = true
				log := make(map[string]interface{})
				line := scanner.Bytes()
				err = json.Unmarshal(line, &log)
				if err != nil {
					return fmt.Errorf("stdout: %s, stderr: %s, err: %v", stdout, stderr, err)
				}
				if _, ok := log["labels"]; !ok {
					return fmt.Errorf("expect the `labels` field to be in existence")
				}
				if _, ok := log["line"]; !ok {
					return fmt.Errorf("expect the `line` field to be in existence")
				}
			}
			if !hasLog {
				return fmt.Errorf("expect least one log to exist")
			}

			return nil
		}).Should(Succeed())
	})
}

func checkLog(title, query string) {
	checkLogCommon(title, func() ([]byte, []byte, error) {
		return ExecAt(boot0,
			"kubectl", "exec", "-n", "logging", "deployment/query-frontend", "--", "logcli", "query", query, "-ojsonl")
	})
}

func checkLogSmall(title, query string) {
	checkLogCommon(title, func() ([]byte, []byte, error) {
		return ExecAt(boot0,
			"kubectl", "exec", "-n", "logging-small", "statefulset/loki-small", "--", "logcli", "query", query, "-ojsonl")
	})
}

func getNodeName(role string) string {
	stdout, stderr, err := ExecAt(boot0, "kubectl", "get", "node", "-l", fmt.Sprintf("node-role.kubernetes.io/%s=true", role), "-o=json")
	Expect(err).ShouldNot(HaveOccurred(), "stdout=%s, stderr=%s", stdout, stderr)

	nodes := new(corev1.NodeList)
	err = json.Unmarshal(stdout, nodes)
	Expect(err).ShouldNot(HaveOccurred())
	Expect(nodes.Items).ShouldNot(BeEmpty())

	return nodes.Items[0].Name
}
