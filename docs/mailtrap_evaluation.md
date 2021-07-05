# Mailtrap evaluation
Many of the links below requires an account to view. Easy demo account [signup here][signup] via Google, Github, or username/password creation.

## [Pricing][pricing]
Free tier may be adequate. If not, Individual tier is $9.99/mo.

### Free tier includes:
* 500 test emails/month at a rate of <= 5 per 10s
* one inbox (so all emails go to one place, like `mailcatcher`)
* max emails per inbox: 50  
  This is a minor problem, but we can just add a job to regularly delete emails via the [API `inbox/:id/clean` endpoint][api]
* use of [API][token] (requires login to view)

### Does not include
* additional team member access
* multiple inboxes or email addresses
* email file size is limited to 5MB

## Setup
Once signed in, you can click on `Demo Inbox` to view `/inboxes/:id/messages` which shows an empty toolbox, but also SMTP config setup details, auto and manual mail forwarding, and an auto-generated code chunk to put into `config/environments/*` to set `ActionMailer` up to use Mailtrap.

### Integration with Mailgun
There is a blog post that talks about using mailtrap with different email services, including Mailgun.

> ## Mailgun test
>
> Mailgun features a very **simple test mode** and an **email verification tool**.
> 1. To launch the test mode, you should simply set the _o:testmode_ parameter to _true_. It will help to test your integration as well. Note that Mailgun charges you for the messages sent in this mode.
> 1. Email verification tool is a specific feature in Mailgun. It is useful for bulk email campaigns. The tool will check all email addresses in your list to identify invalid ones. It helps to decrease hard bounce rate, which has a negative influence on your sending reputation. Note that email verification is a separate limit, not included in the email sending volume.

### SMTP setup details
```txt
SMTP
Host:	smtp.mailtrap.io
Port:	25 or 465 or 587 or 2525
Username:	randomalphanumericstring
Password:	randomalphanumericstring
Auth:	PLAIN, LOGIN and CRAM-MD5
TLS:	Optional (STARTTLS on all ports)

POP3
Host:	pop3.mailtrap.io
Port:	1100 or 9950
Username:	randomalphanumericstring
Password:	randomalphanumericstring
Auth:	USER/PASS, PLAIN, LOGIN, APOP and CRAM-MD5
TLS:	Optional (STARTTLS on all ports)
```

### Code for config/environments/* file
```rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :user_name => 'randomalphanumericstring',
  :password => 'randomalphanumericstring',
  :address => 'smtp.mailtrap.io',
  :domain => 'smtp.mailtrap.io',
  :port => '2525',
  :authentication => :cram_md5
}
```

## Additional info
* [FAQ][faq]

[api]: https://mailtrap.docs.apiary.io/#reference/inbox/apiv1inboxesinboxidclean
[faq]: https://mailtrap.io/faq
[pricing]: https://mailtrap.io/pricing
[signup]:  https://mailtrap.io/register/signup
[token]: https://mailtrap.io/public-api
