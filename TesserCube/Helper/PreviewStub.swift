//
//  PreviewStub.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-10-11.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

#if canImport(SwiftUI) && DEBUG

struct PreviewStub {
    var contacts: [Contact]
    var emails: [Email]
    var keyRecords: [KeyRecord]
    var messages: [Message]
    var messageRecipients: [MessageRecipient]

    static var empty: PreviewStub {
        return PreviewStub(contacts: [], emails: [], keyRecords: [], messages: [], messageRecipients: [])
    }

    func inject() throws {
        try TCDBManager.default.dbQueue.write { db in
            for var contact in contacts {
                try contact.insert(db)
            }

            for var email in emails {
                try email.insert(db)
            }

            for var keyRecord in keyRecords {
                try keyRecord.insert(db)
            }

            for var message in messages {
                try message.insert(db)
            }

            for var messageRecipent in messageRecipients {
                try messageRecipent.insert(db)
            }
        }
    }
}

extension PreviewStub {

    static let `default`: PreviewStub = {
        let names = ["Alice", "Bob", "Carol", "Dan", "Erin"]
        let contacts = names.enumerated().map { Contact(id: Int64($0.0 + 1), name: $0.1) }
        let emails = names.enumerated().map { Email(id: Int64($0.0 + 1), address: $0.1 + "@tessercube.com", contactId: Int64($0.0 + 1)) }
        let keyRecords: [KeyRecord] = {
            let longIdentifiers = ["6A0486D70E04861C", "DE6EAE80E11D78AA", "39611A75DFDD4174", "CE0ABAE54FB29D09", "130A9C2FB95F029B"]
            let hasSecretKeys = [true, false, false, false, false]
            let hasPublicKeys = [true, true, true, true, true]
            let armors = [aliceArmor, bobArmor, carolArmor, danArmor, erinArmor]
            return names.enumerated().map {
                KeyRecord(id: Int64($0.0 + 1), longIdentifier: longIdentifiers[$0.0], hasSecretKey: hasSecretKeys[$0.0], hasPublicKey: hasPublicKeys[$0.0], contactId: Int64($0.0 + 1), armored: armors[$0.0])
            }
        }()
        let messages: [Message] = {
            let message1 = Message(id: 1, senderKeyId: "6A0486D70E04861C", senderKeyUserId: "Alice <alice@tessercube.com>", composedAt: Date(timeIntervalSinceNow: -10.0), interpretedAt: nil, isDraft: false, rawMessage: "Hi, Bob. What time shall we meet tonight for a drink?", encryptedMessage: messageOne)
            let message2 = Message(id: 2, senderKeyId: "DE6EAE80E11D78AA", senderKeyUserId: "Bob <bob@tessercube.com>", composedAt: nil, interpretedAt: Date(), isDraft: false, rawMessage: "Meet at eight in the evening.", encryptedMessage: messageTwo)
            return [message1, message2]
        }()
        let messageRecipients = [
            MessageRecipient(id: nil, messageId: 1, keyId: "DE6EAE80E11D78AA", keyUserId: "Bob <bob@tessercube.com>"),
            MessageRecipient(id: nil, messageId: 2, keyId: "6A0486D70E04861C", keyUserId: "Alice <alice@tessercube.com>"),
        ]

        return PreviewStub(contacts: contacts, emails: emails, keyRecords: keyRecords, messages: messages, messageRecipients: messageRecipients)
    }()

}

private let aliceArmor: String = """
-----BEGIN PGP PRIVATE KEY BLOCK-----
Comment: You can manage keys with https://tessercube.com

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
c+hz401200vfkrS5xQ==
=tgdQ
-----END PGP PRIVATE KEY BLOCK-----
"""

private let bobArmor: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=yMbW
-----END PGP PUBLIC KEY BLOCK-----
"""

private let carolArmor: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=+ACq
-----END PGP PUBLIC KEY BLOCK-----
"""

private let danArmor: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

xsDNBF2gEuUBDADJGR1G38qI/SNw/6OFOrjBCf3MsaTfKITxq5HozgjL/+yFQ07k
yes2ZfrTqmeyONGgxF+8ZZwQwc64Nv+30N5BB5hh2AoKTcCgJZEMwBxOHFdHOUoU
D2RHbSkBjUi9Hq3HPQlalcEENLd/SZTMsJ/wMkgq6Bq/2jCz1PYuEcO3tY38Z9Te
2aOPwkINHyxZvnu32hsnVUiXpH1Iek3sJE3IV0eZkavHWFH8QqkcpnFsJFCk4PFG
wEtxvapiWNxPqTl5vfZ8jU3f+Q4kurvqYjgM7MZju/kWaKnvAyls83hO0wKxXt70
xHCIhGfB1Yjdhw20jtmm5jD92Ebou2QUQpz21iJSutdDKsZWqKa5lJZrgB9MYdbK
H3cHBvKZHMofCNZVqQKV5iZ7cVRBVeKM1p3UTA+lBJp81P0+qEPQkN2xRz0Twqr6
HdCLDqKTYR6wIdldFzw3GSAGAMN514cZP9YC1DonV8hxZK3t9gMje4dep3u9WHGW
T/iD4XjVGsJuvocAEQEAAc0YRGFuIDxEYW5AdGVzc2VyY3ViZS5jb20+wsDoBBMB
CAAcBQJdoBLlCRDOCrrlT7KdCQIbAwIZAQILCQIVCAAAl6oL/jUFOJeN0ERe9pJn
MwVAK26Sp56fr7BXwTZA1dB4nciB7H08L2Ub1OMuxehia3lnaLPII4+YjAf/FD51
Ap0qf1m2tUJyvT4KmcyqeOeDDI4MkmICezerM6MbBwK/zK32ZCbhZ3QbHU/FZ70B
nFvVvhZq3766L9gzq5/ZxEu0vVdql8FVOkJ7hsM3lKdz9h48jUNL2fd61X0geuAh
NzOVWYf8H1/ZL1urTpaZK6lp3PN1SYeuKv7xmDDRa7YA6LF0eI4XWTBMOhQJqWiL
QFM2qjYlX9zN7Bigo52MhRGCx2QdJ33J4UPyHdZczaxN7ZNy4iieYBl1k51WVwrk
a293pJu5aTnYU/UAsDnh/BJXAhDZq3dYgIZSHyYtrot/P7dpy0WKbwxwcryOVorw
FZleNHm6p33JE316wgqn+wSEJ+DWT7WphPMNp97yBxnRzU33xuA7G+seKkNFIIFT
DeYgoGfvHR2jOPEW1F9NM8KDp8eVNHVde5h8/1FvTd2tcqVnqM7AzQRdoBLlAQwA
0CU13WhVn5219XpYq9AeFTmrcB01/z1d77NJdloIkWN8XOTPBFiIZOCubucF/P7j
0TamQGs42aH3y6uPEVu4qQhqtKYK0Sdru6HV3HriUTk6d4vOfz2Vp2o8JvhSYmdp
M3MHqyqTA/sgtz5hCHzBYfIOuCne1Dhh4icoCGfik+3sHBOayLPyUZ3QxK5/VVyG
FRulW8rnvyLI31Z04oSJMBTuJFTsB2cnA0pZA5gWsTN4oQT5PHA0q5yiQeTMu3vm
y3vMPK6GxhsNlnlC6UmHaunCuKpznYfhXwdwy+iKQN/uGkt5WQAM+Jveg1Wpt5VP
3MFhanPYgUdGf349ztUKPu259p77SlljpHUSQQZiTpWcmFHr7elI3shFiSbyeArs
t3CwUJYsL2f7TtjtZXyEzE0ub7iozuGugDkISZNpiyn84rdw3SjIHXpY1YpwrpCd
5jVziPBYe558F18Jyk+rv7Ih8y5SYbe0afhCvzOLoyAzhEdkRdrbXt9TQfZAcLlX
ABEBAAHCwN8EGAEIABMFAl2gEuUJEM4KuuVPsp0JAhsMAABz9Av/UTbRZbrgyL15
0MqpO7JJyQw4gEV3r5Yk8mCYBy4oQrOIcRosOgVAqjTocryMYxysWSvnr4YROvGb
wyQcSXoPZgVsyvjjF3UmLFQTPDr7Fx+7IReB85Jc2kl5hlqYCmbUoGkrS55nYXin
LFCtq8IpL9IyvzyevdKnHEdMFlYuwU+rrK1rGqABYTLuU+TiyFAzmsSyX3+2K0xd
UrmaMn7gRYHERlvboyqx9Xnb1j3NoA7u3iAjQS66SjnzbZI64xzVAniinyjciDDM
9IrasEUUoRvgtaHO/tfPY7jj+g/HkhZQZmVi/zImi+XLd8jbLIvKVPaRgmepm48m
j75dF8uDkE/5rKLyFMWnGTE8chs3iYnOXV+dgGh0IgPFVYeyf1nCGoKTewdQkNW9
ewlrRMD6Oyse0PkMTp5eanJ1m/prCZxQbgVKYmLZcUxKXGIlxuhJ5+9tfeBixLDJ
P/ny7JPRatDWfgE7L0nHH4bSGfGzzrEAMrLV7+X55NT+KayvXNwk
=jlPZ
-----END PGP PUBLIC KEY BLOCK-----
"""

private let erinArmor: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=3Yy9
-----END PGP PUBLIC KEY BLOCK-----
"""

private let messageOne = """
-----BEGIN PGP MESSAGE-----
Comment: Encrypted with https://tessercube.com

wcDMA5leWi5ClFuzAQwAnGR6hcongGhT9DMrCJYdCMvWQe4CJMLK9I7VRtwJ0L4D
C2vc6VPpxFejizPvt3U6Fci+HRD2IKdR+ClCLBP1v7RBDGV6uireY1Syy1AFWaWJ
HFl7qi/jTpwA4ZmcbcwxkkK8cQ6dHhKzmzpjgDaoMrqq8k5/SFHd68Wv/FNXWbeX
7w1M0Ojfu+pUrrEly3OGNvkcNhq3jz8lYAXyiEpQGsWR0HUPk4o8QmVGJ7IEO/c8
o56vLUGWpgi9Z3IB+yIW0qVmzlfW+Dtg2GIrJYdZJ77FcduKqjrEfj4i1a0U2G7I
a5gLAMmc1r+g98X0TNPKVJiS3HMc9YNZWMgUrXSi57ES7tGjPka+mDE4e49aC+Sf
FZjqkejPwRgahH0XzJksvQ2iY/PJ4OjHRVYoG4QXwf9uJdYWor9Iu+dld61NJDbL
ZUd2aBVhCOMs1BHK7rpO74Qb5cFHiy+6VCRaHlWpQMGLGahpYalcmTgCQKjdRKJr
SC22VbnPzQIKAKB/9w4zwcDMA4J0E0oenI+oAQv/eseDxI9zgbp/rs1Vjp6htbc6
lk1ktwpJWdzBbZpxdGW7VaaOg/I0UFMDt2XJ8kjihwKYVKHDdHu+7SEi1bWECtzg
rBfKEKYwWBf7vetW0FrB5qJgApEza/1/SnNYFoEqDNEasvEOoapoYiD+NAFYU26D
ehMYzXAGHiynj+x0W2mxm45lu+e6JwMEiXYwYiV5VyGH67wr7aC+QQk2oTp/WJK8
7ESFYRoXa8jX0WYHg+fCzTjKeW3Zi84p3a7m/+4DJIQG8lpJNNJIcsGO2cYXw4SY
1poG3s3JnM6LZn9wFUUGUgABi+IBjD84D3vLWCa7CTR5lVLuA4+OYkl2NnUklt4v
SW0m3IAxEHUUrlIZbYSQKxZwXjyM5vJclMtRoTEpQw7V+tUOoYehbCMyzb3S2GbN
aVX8nr8/KAG75LZC6aBl5hUDPAYStgzZcp7CdLMh9jB3arHCOVWZgzBW+0c7Efbu
rukkigF4iWQOyPRxw8aqLBGOtOzRHGLIaHXJY7cM0sFUAS842v9EswfljwqTSaCX
Z3/ZuZ1+ScpUHbAcW/2XoOv3+hp20cX9nJFJ7gx1s2XO7eHE2w6c1K17RQjZcu5k
8P6lWGWXFd7N661ozW9pYwdYijDxqJiETq61ISo1cJz7u0nNyGd86mOjAxjIPHZR
6M9xTttt0fHyhtstG4sQ204g1DC64qbCOcNM7P0wweNr6+MUl3MRzbVJwM749YLy
ZwElJY4F3Qj7t+fS0VblI0Zu/1g3MrWm8poSwu2mmlvZmUFJpbh7pF0DhyXz2CbX
/zm8l2qayXAoM0MPAbrjry1nJVNQHne02o9BKI9DcD6QXEM8piW9x6hsyhwr8K6T
jjDMvn09cbOdm593puCxQ2MVhxT/wX6xBnhxpZAJfEAS8NJKQvUeQtkHdhB1UIms
95c3dVAlnejrPi2O6KwDP/CwLGiOfkjYJzFLnwdE1bwqUaTWzim2hCU0GUdzqa0S
usDpPxDm5XqcIm7J1tWm/oOAun1Yii16dlVtVO3uZyK6PkppBnVp/p0zFPa5CPhr
NIPrI6PibOEsNBWduoijIU/ZhWg5wEYDxVVr31hwLHvGRcwUzpfleWh4xEHEFPOr
KEcf6CQHrOYoP7EYjHkbIoR16hhYJJQ+72pH3GR4d0zqf9F6HKWUqOVH+c+KN7HL
lLoHpPov2AgZ8mbaTKiokXw4inq6z6tpqoSWXkTWZc9/jZo2pg==
=yBsJ
-----END PGP MESSAGE-----
"""

private let messageTwo = """
-----BEGIN PGP MESSAGE-----
Comment: Encrypted with https://tessercube.com

wcDMA4J0E0oenI+oAQv9FgRwwhBloRzOJUdlGa7jMu8gdwtyOlFZO7mMW5/edXPK
+VoimA6HssK1F9VEbnz/JrgwpYYStL/cinDrq8fOYTykiuriFIuS2US07NinYCVE
M0+eqVmy1+vXnE72KX8Sk1SZnb1bTB8fjK1gbRlh8JEyED9rAwJx6ZniQZ/3SlIB
MV28fPKCPgoJUuMcXhYzCtSP4UvOFUmrdjbqkaUsOnhWWxiJMv9/5X2x57k0aW0H
AdLtDU3AjdMK9rtLTa8SUc549bsjgMWWi02r0Og0ZqNqvbTm6QSc0xMs7UEbgSsQ
8/RAeXV2gQi37c9EfAI/gECHcAkoRLytSlvtshzQi52atevhSh8Zv1OE9bGZoEx4
f4zJBe2BlW7g7J5xxuwTGXGOKMsKaUxEjzQFo5JnNMXS0FFUGFU/3q/Oi5BoCrqu
esmHi0MMtNzqSv95O7dUaEgiDG095A0dbD0Dfg+OyKnZoqHxwh1GvpOGDT7euuCq
MDs/OqJLMOt/HUHJJ+E/wcDMA5leWi5ClFuzAQwAoESzomhb5fmwD2n3zlOQMjKN
VE4mK+9N8O8ZSCULx3rmNZoc33EigSJkfOH/YWGpMJy4tUIvaaXSKkdg0cQSWkzr
kUThNo4933bpFURAZ6ToDY6IhYrqJPIlKPLYyN/ZH5Mv45cpGhQHjeSHwVxn6WHZ
quEVAJpSN78JLbQP+YDbfTQrJHPtlzuOH3EFuFFjZTlG4XT2r1q8Lheuqyo87pM4
Onm2oeny5vpxRfryo8dMB0jlQN/AvUy4pD6rT+g/LkqkYhDLTiXcAymWBsvV+U3L
9qOc+wRFLxqgeJ9z4i9PLPybG2iKIBNx71DTzlPPU0BU8Vo635KjepuuN7vjM2rW
VgjBlSfznzaNiZMGlmq77ujDA+MCpdfwUt7KrBCWBlr2Us0Cj0Q/lzDmg9ggbheb
hb+MIEW4DLajoywHF3Wh8DnrMpy5yYaHBGdLfrKv9K2wxu7RlEPfdrPHiRuXXUaf
5jvQFzkn9GXLIjP8wrwXhryKvnl0T8P60+uMOt7+0sE8ATo3OH7QG6gB0NWlhI4W
0MA9W7ZHt2+gktoEWb6NPj2W46RYDxaBJZpsFEsRuK7oshRCaj/7pKJz3N0ty2Mm
+bnJizH85dRaJ+5pEcRFlywk9jYnWV56zL9x5r0/hrV5+R4LZ5Dge9KjKhleKh6m
Aen9cyCVzefghBbf7J+PBwXAJsGAYwgC/CMT2q+OMnK4OI1zoIVmtHOKj4zsIrmJ
MYlsW+mjLcLeXDy88EEru2YKp1EDGy50R9UesgaEfamI5708nUUhJOtAvSk7roJG
tUCsD3dVZtLISXQRMVmUtQ8gO1BOkxRl+KZc69ApHGaofAtAkXEh525tZExGAsEl
BDwCInMNLF40P50Lgh7VaiLPZpv3LRUdBPy1JYo0h6ltY9HehPej7lV8s7ghL0Av
z0bvZeW2NlzMcc/k+39pxndq6fDPjIsN3G+mRe5EZR3QxnRDoV5YwZ1z5h7d10o+
vw3zWOKK4Z+dTBGoiUQoSFgbbanSyY2jdg1wvnXkIrL+ym1dzXv/9wHAyMkHbOS3
N6LR423Tx4vwSOe6SIR1kE3iZvzYG2pWQGWpasX7CjbCI51thuX1sOZyjluoruMZ
/gJB3f3umO+HsApfmDKiFoaR6SDq5HkDkMgeL/8RW0kOYxy6pJa+MnWpwShu5bUQ
rRYqBUfNmpVPgo2o7g==
=hX1w
-----END PGP MESSAGE-----
"""
#endif
