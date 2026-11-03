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

The package root also exposes a small certificate-verified IMAP4 client for
polling an operational bounce mailbox one unseen message at a time. The default
fetch marks a complete message seen; durable consumers can instead peek, commit
their feedback event, and then mark that exact UID seen. Consumers do not need a
repository-relative import to ingest delivery feedback.

Replies set `inReplyTo` and `references` (Message-IDs, brackets optional);
`extraTo` and `cc` add plain addresses that all receive the message. A message
with an empty `htmlBody` is sent as plain text alone. `smtpRenderMessage` gives
the exact text that is sent, so it can be filed in Sent with `imapAppend`.

## Mailboxes

For agents and services that read their own mail, each call below opens one
connection, logs in, does its work and logs out. Folder names are printable
ASCII; UIDs are decimal strings.

```abla
imapListMessages(config, "INBOX", limit = 20, afterUid = "")      // ImapListResult
imapSearchMessages(config, "INBOX", ImapQuery(unseen = true, from = "x@y.pt",
    subject = "fatura", since = "2026-11-01", text = "...", afterUid = ""), 20)
imapFetchMessage(config, "INBOX", uid, maximumBytes = 8388608)    // ImapMessage, stays unseen
imapSetSeen(config, "INBOX", uid, true)                           // ImapActionResult
imapAppend(config, "Sent", smtpRenderMessage(message))            // ImapAppendResult
mimeParse(fetched.raw)                                            // MimeMessage
```

Listings are newest first with UID, From, To, Cc, Subject, Date, Message-ID,
In-Reply-To, References, the seen flag and size; `matched` counts every match.
Search terms may be UTF-8. A fetch never sets `\Seen`, and a message over
`maximumBytes` comes back cut short with `truncated` set.

`mimeParse` turns a raw message into decoded headers and plain text: it prefers
text/plain in multipart/alternative, converts HTML to text otherwise, decodes
quoted-printable, base64 and RFC 2047/2231 names, reads UTF-8 and Latin-1
(as Windows-1252), and lists attachments by name, type and decoded size without
decoding them. Text is limited to 1 MiB, nesting to 8 levels and parts to 256.

Responses are read line by line, following IMAP literals, so message contents
can't end a response early. Every response, line and literal is bounded, read
and write timeouts follow `timeoutMilliseconds` (1–60 s), and errors never
contain credentials.

`make test` runs the offline tests. `make live` runs `tests/live_mail_test.ab`
against real test mailboxes named in the environment; it sends mail only between
them.
