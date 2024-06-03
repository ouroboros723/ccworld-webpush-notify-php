<?php

namespace App\Services;

use Minishlink\WebPush\MessageSentReport;
use Minishlink\WebPush\WebPush;
use Minishlink\WebPush\Subscription;

class WebPushService {
    public function send(array $clientSidePushSubscription) {
        // store the client-side `PushSubscription` object (calling `.toJSON` on it) as-is and then create a WebPush\Subscription from it
        $subscription = Subscription::create($clientSidePushSubscription);

        // array of notifications
        $notifications = [
            [
                'subscription' => $subscription,
                'payload' => '{"message":"Hello World!"}',
            ], [
                // current PushSubscription format (browsers might change this in the future)
                'subscription' => Subscription::create([
                    "endpoint" => "",
                    "keys" => [
                        'p256dh' => '(stringOf88Chars)',
                        'auth' => '(stringOf24Chars)'
                    ],
                ]),
                'payload' => '{"message":"Hello World!"}',
            ], [
                // old Firefox PushSubscription format
                'subscription' => Subscription::create([
                    'endpoint' => 'https://updates.push.services.mozilla.com/push/abc...', // Firefox 43+,
                    'publicKey' => 'BPcMbnWQL5GOYX/5LKZXT6sLmHiMsJSiEvIFvfcDvX7IZ9qqtq68onpTPEYmyxSQNiH7UD/98AUcQ12kBoxz/0s=', // base 64 encoded, should be 88 chars
                    'authToken' => 'CxVX6QsVToEGEcjfYPqXQw==', // base 64 encoded, should be 24 chars
                ]),
                'payload' => 'hello !',
            ], [
                // old Chrome PushSubscription format
                'subscription' => Subscription::create([
                    'endpoint' => 'https://fcm.googleapis.com/fcm/send/abcdef...',
                ]),
                'payload' => null,
            ], [
                // old PushSubscription format
                'subscription' => Subscription::create([
                    'endpoint' => 'https://example.com/other/endpoint/of/another/vendor/abcdef...',
                    'publicKey' => '(stringOf88Chars)',
                    'authToken' => '(stringOf24Chars)',
                    'contentEncoding' => 'aesgcm', // one of PushManager.supportedContentEncodings
                ]),
                'payload' => '{"message":"test"}',
            ]
        ];

        $webPush = new WebPush();

// send multiple notifications with payload
        foreach ($notifications as $notification) {
            $webPush->queueNotification(
                $notification['subscription'],
                $notification['payload'] // optional (defaults null)
            );
        }

        /**
         * Check sent results
         * @var MessageSentReport $report
         */
        foreach ($webPush->flush() as $report) {
            $endpoint = $report->getRequest()->getUri()->__toString();

            if ($report->isSuccess()) {
                echo "[v] Message sent successfully for subscription {$endpoint}.";
            } else {
                echo "[x] Message failed to sent for subscription {$endpoint}: {$report->getReason()}";
            }
        }

        /**
         * send one notification and flush directly
         * @var MessageSentReport $report
         */
        $report = $webPush->sendOneNotification(
            $notifications[0]['subscription'],
            $notifications[0]['payload'], // optional (defaults null)
        );
    }
}
