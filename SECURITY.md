# Security

## Trust boundary

This plugin is an askpass UI for a trusted, single-user desktop session. It is
not a privilege boundary or a replacement for sudo's authentication and policy.

- The Shell IPC endpoint accepts requests from processes in the same session.
  It does not authenticate a request as coming from sudo. A same-user process
  can spoof the dialog's command and supply its own response FIFO.
- The QML UI runs in Omarchy Shell alongside other unsandboxed plugins. It
  does not receive the special isolation of first-party authentication services.
  Do not use it with plugins or same-user processes you do not trust.
- The command shown by the supplied helper is sudo's argv from `/proc`. It does
  not describe later actions, script contents, shell expansions inside a script,
  executable changes or the complete effects of running that command.
- Cached sudo credentials skip askpass. This is not a command-approval gate.
- Passwords exist transiently in process memory. Clearing QML/Bash strings is
  not guaranteed memory zeroization; swap and core dumps are outside this UI's
  control. Command arguments may themselves contain secrets and will be shown.

## Handling

The helper uses private runtime directories (`0700`) and FIFOs (`0600`), a bounded
response wait and a per-user lock. The UI rejects symlink response paths and
checks directory/FIFO ownership and permissions before writing. These checks
are defense in depth, not protection from a malicious process with the same UID.
Passwords travel via process stdin and FIFO contents; they are not placed in
command arguments, environment variables or regular files by this plugin.

## Reporting

Use [GitHub private vulnerability reporting](https://github.com/FLX-0x00/omarchy-askpass/security/advisories/new).
Do not include real passwords, tokens or unredacted desktop captures. Include
the plugin commit, Omarchy/Quickshell versions and a reproduction using dummy
data. Reports outside the trust boundary above are still useful when they
identify misleading UI, unexpected disclosure or a practical hardening measure.
