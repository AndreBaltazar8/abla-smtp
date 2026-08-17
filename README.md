# Abla SMTP

Small SMTP submission and MIME library for Abla services. It uses certificate-
verified implicit TLS (normally port 465), AUTH PLAIN inside TLS, bounded SMTP
replies, UTF-8 encoded headers, multipart text/HTML bodies, base64 transfer
encoding and dot stuffing.

Connection setup is bounded to Abla's supported 1–10 second TCP window even if
the caller supplies a wider timeout.

Subscription messages can include RFC 8058 one-click unsubscribe headers and a
Gmail Feedback Loop identifier.
Delivery policy is deliberately left to the application: a `4xx` result is
marked retryable and a `5xx` recipient rejection permanent, so an outbox can
retry with backoff or suppress the rejected address.

```abla
import github("AndreBaltazar8/abla-smtp")

val result = smtpSend(config, message)
```

The caller supplies the RFC 5322 date and globally unique Message-ID. Passwords
should come from mounted secret files and must never be logged. Use separate
sender identities and lists for transactional mail and consented product news.

`src/imap.ab` also contains a small certificate-verified IMAP4 client for
polling an operational bounce mailbox one unseen message at a time. It uses UID
commands and marks a message seen only after a complete fetch.
