// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum Common {
    internal enum Alert {
      /// Error
      internal static let error = L10n.tr("Localizable", "Common.Alert.Error")
      /// Unknown Error
      internal static let unknownError = L10n.tr("Localizable", "Common.Alert.UnknownError")
    }
    internal enum Button {
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "Common.Button.Cancel")
      /// Delete
      internal static let delete = L10n.tr("Localizable", "Common.Button.Delete")
      /// Discard
      internal static let discard = L10n.tr("Localizable", "Common.Button.Discard")
      /// Edit
      internal static let edit = L10n.tr("Localizable", "Common.Button.Edit")
      /// OK
      internal static let ok = L10n.tr("Localizable", "Common.Button.OK")
    }
    internal enum Hud {
      /// Creating key, please wait...
      internal static let creatingKey = L10n.tr("Localizable", "Common.HUD.CreatingKey")
      /// Importing key, please wait...
      internal static let importingKey = L10n.tr("Localizable", "Common.HUD.ImportingKey")
    }
    internal enum Label {
      /// [None]
      internal static let nameNone = L10n.tr("Localizable", "Common.Label.NameNone")
      /// [null]
      internal static let nameNull = L10n.tr("Localizable", "Common.Label.NameNull")
      /// [Unknown]
      internal static let nameUnknown = L10n.tr("Localizable", "Common.Label.NameUnknown")
    }
  }

  internal enum ComposeMessageViewController {
    /// Compose
    internal static let title = L10n.tr("Localizable", "ComposeMessageViewController.Title")
    internal enum Alert {
      internal enum Action {
        /// Save Draft
        internal static let saveDraft = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Action.SaveDraft")
        /// Update Draft
        internal static let updateDraft = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Action.UpdateDraft")
      }
      internal enum Message {
        /// Not found encryption key in keyring: %@
        internal static func missingEncryptionKey(_ p1: String) -> String {
          return L10n.tr("Localizable", "ComposeMessageViewController.Alert.Message.MissingEncryptionKey", p1)
        }
        /// Skip & Finish
        internal static let skipAndFinish = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Message.SkipAndFinish")
      }
      internal enum Title {
        /// Missing encryption key
        internal static let missingEncryptionKey = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Title.MissingEncryptionKey")
        /// Save draft?
        internal static let saveDraft = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Title.SaveDraft")
        /// Skip invalid recipeints
        internal static let skipInvalidResipients = L10n.tr("Localizable", "ComposeMessageViewController.Alert.Title.SkipInvalidResipients")
      }
    }
    internal enum BarButtonItem {
      /// Finish
      internal static let finish = L10n.tr("Localizable", "ComposeMessageViewController.BarButtonItem.Finish")
    }
    internal enum RecipientContactPickerView {
      internal enum TitleLabel {
        internal enum Text {
          /// To:
          internal static let to = L10n.tr("Localizable", "ComposeMessageViewController.RecipientContactPickerView.TitleLabel.Text.To")
        }
      }
    }
    internal enum SenderContactPickerView {
      internal enum TitleLabel {
        internal enum Text {
          /// From:
          internal static let from = L10n.tr("Localizable", "ComposeMessageViewController.SenderContactPickerView.TitleLabel.Text.From")
        }
      }
    }
    internal enum TextView {
      internal enum Message {
        /// Message goes here...
        internal static let placeholder = L10n.tr("Localizable", "ComposeMessageViewController.TextView.Message.Placeholder")
      }
    }
  }

  internal enum ContactDetailViewController {
    internal enum Button {
      /// Send Message
      internal static let sendMessage = L10n.tr("Localizable", "ContactDetailViewController.Button.SendMessage")
    }
    internal enum Label {
      /// created at
      internal static let createdAt = L10n.tr("Localizable", "ContactDetailViewController.Label.CreatedAt")
      /// email
      internal static let email = L10n.tr("Localizable", "ContactDetailViewController.Label.Email")
      /// fingerprint
      internal static let fingerprint = L10n.tr("Localizable", "ContactDetailViewController.Label.Fingerprint")
      /// Invalid
      internal static let invalid = L10n.tr("Localizable", "ContactDetailViewController.Label.Invalid")
      /// Invalid Fingerprint
      internal static let invalidFingerprint = L10n.tr("Localizable", "ContactDetailViewController.Label.InvalidFingerprint")
      /// type
      internal static let keytype = L10n.tr("Localizable", "ContactDetailViewController.Label.Keytype")
      /// Valid
      internal static let valid = L10n.tr("Localizable", "ContactDetailViewController.Label.Valid")
      /// validity
      internal static let validity = L10n.tr("Localizable", "ContactDetailViewController.Label.Validity")
    }
  }

  internal enum ContactListViewController {
    internal enum EmptyView {
      /// You do not have any contact yet.\nAdd contacts by importing their public keys.
      internal static let prompt = L10n.tr("Localizable", "ContactListViewController.EmptyView.Prompt")
    }
  }

  internal enum CreateNewKeyViewController {
    internal enum Alert {
      /// Confirm password should be same as password
      internal static let confirmPasswordNotSame = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.ConfirmPasswordNotSame")
      /// Please input a valid email address
      internal static let emailInvalid = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.EmailInvalid")
      /// Email is required to create a key
      internal static let emailRequired = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.EmailRequired")
      /// Name is required to create a key
      internal static let nameRequired = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.NameRequired")
      internal enum Title {
        /// Please input a valid email address
        internal static let emailInvalid = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.Title.EmailInvalid")
        /// Email is required to create a key
        internal static let emailRequired = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.Title.EmailRequired")
        /// Name is required to create a key
        internal static let nameRequired = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.Title.NameRequired")
        /// Confirm password should be same as password
        internal static let passwordNotMatch = L10n.tr("Localizable", "CreateNewKeyViewController.Alert.Title.PasswordNotMatch")
      }
    }
    internal enum Label {
      /// Algorithm
      internal static let algorithm = L10n.tr("Localizable", "CreateNewKeyViewController.Label.Algorithm")
      /// Confirm Password
      internal static let confirmPassword = L10n.tr("Localizable", "CreateNewKeyViewController.Label.ConfirmPassword")
      /// Easy Mode
      internal static let easymode = L10n.tr("Localizable", "CreateNewKeyViewController.Label.Easymode")
      /// Email
      internal static let email = L10n.tr("Localizable", "CreateNewKeyViewController.Label.Email")
      /// Key Length
      internal static let keyLength = L10n.tr("Localizable", "CreateNewKeyViewController.Label.KeyLength")
      /// Name
      internal static let name = L10n.tr("Localizable", "CreateNewKeyViewController.Label.Name")
      /// Password
      internal static let password = L10n.tr("Localizable", "CreateNewKeyViewController.Label.Password")
    }
  }

  internal enum DMSPGPError {
    /// Internal Error
    internal static let `internal` = L10n.tr("Localizable", "DMSPGPError.internal")
    /// Invalid Message Format
    internal static let invalidArmored = L10n.tr("Localizable", "DMSPGPError.invalidArmored")
    /// Invalid Cleartext Format
    internal static let invalidCleartext = L10n.tr("Localizable", "DMSPGPError.invalidCleartext")
    /// Curve must be provided for this algorithm
    internal static let invalidCurve = L10n.tr("Localizable", "DMSPGPError.invalidCurve")
    /// Internal Error (KeyID)
    internal static let invalidKeyID = L10n.tr("Localizable", "DMSPGPError.invalidKeyID")
    /// Invalid key length
    internal static let invalidKeyLength = L10n.tr("Localizable", "DMSPGPError.invalidKeyLength")
    /// Invalid Message Format
    internal static let invalidMessage = L10n.tr("Localizable", "DMSPGPError.invalidMessage")
    /// Invalid Private Key Format
    internal static let invalidPrivateKey = L10n.tr("Localizable", "DMSPGPError.invalidPrivateKey")
    /// Invalid Public Key Format
    internal static let invalidPublicKeyRing = L10n.tr("Localizable", "DMSPGPError.invalidPublicKeyRing")
    /// Invalid SecretKey Password
    internal static let invalidSecrectKeyPassword = L10n.tr("Localizable", "DMSPGPError.invalidSecrectKeyPassword")
    /// Invalid Secret Key Format
    internal static let invalidSecretKeyRing = L10n.tr("Localizable", "DMSPGPError.invalidSecretKeyRing")
    /// Missing Encryption Key: %@
    internal static func missingEncryptionKey(_ p1: String) -> String {
      return L10n.tr("Localizable", "DMSPGPError.missingEncryptionKey", p1)
    }
    /// Invalid Message Format
    internal static let notArmoredInput = L10n.tr("Localizable", "DMSPGPError.notArmoredInput")
    /// Algorithm %@ is not supported
    internal static func notSupportAlgorithm(_ p1: String) -> String {
      return L10n.tr("Localizable", "DMSPGPError.notSupportAlgorithm", p1)
    }
  }

  internal enum EditContactViewController {
    internal enum Action {
      internal enum Button {
        /// Would you like to delete this contact?
        internal static let confirmDeleteContact = L10n.tr("Localizable", "EditContactViewController.Action.Button.ConfirmDeleteContact")
        /// Would you like to keep the public key of this contact?
        internal static let confirmDeleteKeypairs = L10n.tr("Localizable", "EditContactViewController.Action.Button.ConfirmDeleteKeypairs")
        /// Delete Key Pairs
        internal static let deleteKeyPair = L10n.tr("Localizable", "EditContactViewController.Action.Button.DeleteKeyPair")
        /// Keep Public Key
        internal static let keepPublicKey = L10n.tr("Localizable", "EditContactViewController.Action.Button.KeepPublicKey")
      }
    }
    internal enum EditType {
      /// Name
      internal static let name = L10n.tr("Localizable", "EditContactViewController.EditType.Name")
      /// Trust
      internal static let trust = L10n.tr("Localizable", "EditContactViewController.EditType.Trust")
    }
    internal enum Label {
      /// Delete Contact
      internal static let deleteContact = L10n.tr("Localizable", "EditContactViewController.Label.DeleteContact")
    }
  }

  internal enum ImportKeyController {
    internal enum Action {
      internal enum Button {
        /// Maybe Later
        internal static let maybeLater = L10n.tr("Localizable", "ImportKeyController.Action.Button.MaybeLater")
        /// Paste Private Key
        internal static let pastePrivateKey = L10n.tr("Localizable", "ImportKeyController.Action.Button.PastePrivateKey")
        /// Scan QR Code
        internal static let scanQR = L10n.tr("Localizable", "ImportKeyController.Action.Button.ScanQR")
      }
    }
    internal enum Prompt {
      /// From another device...
      internal static let fromAnotherDevice = L10n.tr("Localizable", "ImportKeyController.Prompt.FromAnotherDevice")
      /// From another OpenPGP app...
      internal static let fromPGP = L10n.tr("Localizable", "ImportKeyController.Prompt.FromPGP")
      /// From a previous backup...
      internal static let fromPreviousBackup = L10n.tr("Localizable", "ImportKeyController.Prompt.FromPreviousBackup")
    }
  }

  internal enum InterpretMessageViewController {
    /// Interpret
    internal static let title = L10n.tr("Localizable", "InterpretMessageViewController.Title")
  }

  internal enum InterpretMessageViewModel {
    internal enum Alert {
      internal enum Message {
        /// The message payload is invalid.\nPlease verify again.
        internal static let badPayload = L10n.tr("Localizable", "InterpretMessageViewModel.Alert.Message.BadPayload")
      }
      internal enum Title {
        /// Bad Payload
        internal static let badPayload = L10n.tr("Localizable", "InterpretMessageViewModel.Alert.Title.BadPayload")
      }
    }
  }

  internal enum IntroWizardViewController {
    internal enum Action {
      internal enum Button {
        /// Not Now
        internal static let notNow = L10n.tr("Localizable", "IntroWizardViewController.Action.Button.notNow")
        /// Skip Guides
        internal static let skipGuides = L10n.tr("Localizable", "IntroWizardViewController.Action.Button.skipGuides")
      }
    }
    internal enum Step {
      /// 🎉 Guide Completed 🎉\nCreate a keypair right now?
      internal static let completeGuide = L10n.tr("Localizable", "IntroWizardViewController.Step.completeGuide")
      /// Tap "Compose" to encrypt a message or create a signature; or both.
      internal static let composeMessage = L10n.tr("Localizable", "IntroWizardViewController.Step.composeMessage")
      /// This is where you manage your contacts.
      internal static let contactsScene = L10n.tr("Localizable", "IntroWizardViewController.Step.contactsScene")
      /// Tap "+" to create a keypair or import your existing keypairs.
      internal static let createKeyPair = L10n.tr("Localizable", "IntroWizardViewController.Step.createKeyPair")
      /// Tap "+" to import a contact with their public key.
      internal static let importContact = L10n.tr("Localizable", "IntroWizardViewController.Step.importContact")
      /// Tap "Interpret" to decrypt a message or verify a signature, or both.
      internal static let interpretMessage = L10n.tr("Localizable", "IntroWizardViewController.Step.interpretMessage")
      /// This is where you manage your private keys.
      internal static let meScene = L10n.tr("Localizable", "IntroWizardViewController.Step.meScene")
      /// This is where you manage your message history.
      internal static let messagesScene = L10n.tr("Localizable", "IntroWizardViewController.Step.messagesScene")
    }
  }

  internal enum Keyboard {
    internal enum Alert {
      /// No encrypted text or digital signature found.
      internal static let noEncryptedText = L10n.tr("Localizable", "Keyboard.Alert.NoEncryptedText")
      /// Select at least 1 recipeint to encrypt.
      internal static let noSelectedRecipient = L10n.tr("Localizable", "Keyboard.Alert.NoSelectedRecipient")
    }
    internal enum Button {
      /// Encrypt
      internal static let encrypt = L10n.tr("Localizable", "Keyboard.Button.Encrypt")
      /// Interpret
      internal static let interpret = L10n.tr("Localizable", "Keyboard.Button.Interpret")
    }
    internal enum Interpreted {
      internal enum Content {
        /// You do not have the necessary private key to decrypt this message.
        internal static let noNeccessaryPrivateKey = L10n.tr("Localizable", "Keyboard.Interpreted.Content.NoNeccessaryPrivateKey")
      }
      internal enum Title {
        /// Bad Signature: Possibly Fake Sender
        internal static let badSignature = L10n.tr("Localizable", "Keyboard.Interpreted.Title.BadSignature")
        /// Message Interpreted
        internal static let messageInterpreted = L10n.tr("Localizable", "Keyboard.Interpreted.Title.MessageInterpreted")
        /// Cannot Decrypt Message
        internal static let noNeccessaryPrivateKey = L10n.tr("Localizable", "Keyboard.Interpreted.Title.NoNeccessaryPrivateKey")
        /// Unknown Sender: Keep Caution
        internal static let unknownSender = L10n.tr("Localizable", "Keyboard.Interpreted.Title.UnknownSender")
      }
    }
    internal enum Label {
      /// No contacts found
      internal static let noContactsFound = L10n.tr("Localizable", "Keyboard.Label.NoContactsFound")
      /// One contact found
      internal static let oneContactFound = L10n.tr("Localizable", "Keyboard.Label.OneContactFound")
      /// %lu contacts found
      internal static func pluralContactFound(_ p1: Int) -> String {
        return L10n.tr("Localizable", "Keyboard.Label.PluralContactFound", p1)
      }
      /// Select Recipients
      internal static let selectRecipients = L10n.tr("Localizable", "Keyboard.Label.SelectRecipients")
    }
    internal enum Prompt {
      /// Click to enable "Full Access" please
      internal static let enableFullAccess = L10n.tr("Localizable", "Keyboard.Prompt.EnableFullAccess")
    }
  }

  internal enum MainTabbarViewController {
    internal enum TabBarItem {
      internal enum Contacts {
        /// Contacts
        internal static let title = L10n.tr("Localizable", "MainTabbarViewController.TabBarItem.Contacts.title")
      }
      internal enum Me {
        /// Me
        internal static let title = L10n.tr("Localizable", "MainTabbarViewController.TabBarItem.Me.title")
      }
      internal enum Messages {
        /// Messages
        internal static let title = L10n.tr("Localizable", "MainTabbarViewController.TabBarItem.Messages.title")
      }
    }
  }

  internal enum MeViewController {
    internal enum Action {
      /// Create or import a key to start using.
      internal static let prompt = L10n.tr("Localizable", "MeViewController.Action.Prompt")
      internal enum Button {
        /// Yes, Delete 
        internal static let confirmDeleteKey = L10n.tr("Localizable", "MeViewController.Action.Button.ConfirmDeleteKey")
        /// Create Keypair
        internal static let createKey = L10n.tr("Localizable", "MeViewController.Action.Button.CreateKey")
        /// Export Private Key
        internal static let export = L10n.tr("Localizable", "MeViewController.Action.Button.Export")
        /// Import Keypair
        internal static let importKey = L10n.tr("Localizable", "MeViewController.Action.Button.ImportKey")
        /// Scan QR Code
        internal static let scanQR = L10n.tr("Localizable", "MeViewController.Action.Button.ScanQR")
        /// Settings
        internal static let settings = L10n.tr("Localizable", "MeViewController.Action.Button.Settings")
        /// Share Public Key
        internal static let share = L10n.tr("Localizable", "MeViewController.Action.Button.Share")
      }
    }
    internal enum KeyCardCell {
      internal enum Label {
        /// Invalid Fingerprint
        internal static let invalidFingerprint = L10n.tr("Localizable", "MeViewController.KeyCardCell.Label.InvalidFingerprint")
        /// No keypair yet
        internal static let noKeyYet = L10n.tr("Localizable", "MeViewController.KeyCardCell.Label.NoKeyYet")
      }
    }
  }

  internal enum MessageCardCell {
    internal enum Button {
      internal enum Expand {
        /// Collapse
        internal static let collapse = L10n.tr("Localizable", "MessageCardCell.Button.Expand.collapse")
        /// Show full %lu lines
        internal static func expand(_ p1: Int) -> String {
          return L10n.tr("Localizable", "MessageCardCell.Button.Expand.expand", p1)
        }
      }
    }
    internal enum Label {
      ///  composed
      internal static let composed = L10n.tr("Localizable", "MessageCardCell.Label.Composed")
      ///  last edited
      internal static let edited = L10n.tr("Localizable", "MessageCardCell.Label.Edited")
      ///  interpreted
      internal static let interpret = L10n.tr("Localizable", "MessageCardCell.Label.Interpret")
      /// Recipeints:
      internal static let recipeints = L10n.tr("Localizable", "MessageCardCell.Label.Recipeints")
      /// Signed by:
      internal static let signedBy = L10n.tr("Localizable", "MessageCardCell.Label.SignedBy")
    }
  }

  internal enum MessagesViewController {
    internal enum Action {
      internal enum Button {
        /// Compose
        internal static let compose = L10n.tr("Localizable", "MessagesViewController.Action.Button.Compose")
        /// Copy Message Content
        internal static let copyMessageContent = L10n.tr("Localizable", "MessagesViewController.Action.Button.CopyMessageContent")
        /// Copy Raw Payload
        internal static let copyRawPayload = L10n.tr("Localizable", "MessagesViewController.Action.Button.CopyRawPayload")
        /// Interpret
        internal static let interpret = L10n.tr("Localizable", "MessagesViewController.Action.Button.Interpret")
        /// Mark as Finished
        internal static let markAsFinished = L10n.tr("Localizable", "MessagesViewController.Action.Button.MarkAsFinished")
        /// Re-compose
        internal static let reCompose = L10n.tr("Localizable", "MessagesViewController.Action.Button.ReCompose")
        /// Share Encrypted Message
        internal static let shareEncryptedMessage = L10n.tr("Localizable", "MessagesViewController.Action.Button.ShareEncryptedMessage")
        /// Share Signed Message
        internal static let shareSignedMessage = L10n.tr("Localizable", "MessagesViewController.Action.Button.ShareSignedMessage")
      }
    }
    internal enum Alert {
      internal enum Title {
        /// Delete Message?
        internal static let deleteMessage = L10n.tr("Localizable", "MessagesViewController.Alert.Title.DeleteMessage")
      }
    }
    internal enum EmptyView {
      /// No message yet.\nYou can compose and interpret messages.\nMessages composed and interpreted in\nTessercube keyboard will appear here.
      internal static let prompt = L10n.tr("Localizable", "MessagesViewController.EmptyView.Prompt")
      /// No message.
      internal static let searchingPrompt = L10n.tr("Localizable", "MessagesViewController.EmptyView.SearchingPrompt")
    }
    internal enum SegmentedControl {
      /// Saved Drafts
      internal static let savedDrafts = L10n.tr("Localizable", "MessagesViewController.SegmentedControl.savedDrafts")
      /// Timeline
      internal static let timeline = L10n.tr("Localizable", "MessagesViewController.SegmentedControl.timeline")
    }
  }

  internal enum PasteKeyViewController {
    internal enum Placeholder {
      /// Password
      internal static let password = L10n.tr("Localizable", "PasteKeyViewController.Placeholder.Password")
    }
    internal enum Title {
      /// Import Public Key
      internal static let importPublicKey = L10n.tr("Localizable", "PasteKeyViewController.Title.ImportPublicKey")
      /// Paste Private Key
      internal static let pastePrivateKey = L10n.tr("Localizable", "PasteKeyViewController.Title.PastePrivateKey")
    }
  }

  internal enum SettingsViewController {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsViewController.Title")
    internal enum Settings {
      /// Message Digital Signature
      internal static let messageDigitalSignature = L10n.tr("Localizable", "SettingsViewController.Settings.MessageDigitalSignature")
      /// Show Lowercase Keys
      internal static let showLowercaseKeys = L10n.tr("Localizable", "SettingsViewController.Settings.ShowLowercaseKeys")
      internal enum MessageDigitalSignature {
        internal enum Automatic {
          /// Automatic (Top in list)
          internal static let long = L10n.tr("Localizable", "SettingsViewController.Settings.MessageDigitalSignature.Automatic.long")
          /// Automatic
          internal static let short = L10n.tr("Localizable", "SettingsViewController.Settings.MessageDigitalSignature.Automatic.short")
        }
        internal enum NotSign {
          /// Do not sign messages
          internal static let long = L10n.tr("Localizable", "SettingsViewController.Settings.MessageDigitalSignature.NotSign.long")
          /// Not Sign
          internal static let short = L10n.tr("Localizable", "SettingsViewController.Settings.MessageDigitalSignature.NotSign.short")
        }
      }
    }
    internal enum TableView {
      internal enum Header {
        /// Keyboard
        internal static let keyboard = L10n.tr("Localizable", "SettingsViewController.TableView.Header.Keyboard")
      }
    }
  }

  internal enum SharePosterController {
    /// Share Public Key
    internal static let title = L10n.tr("Localizable", "SharePosterController.Title")
    internal enum Action {
      internal enum Button {
        /// Save Image
        internal static let saveImage = L10n.tr("Localizable", "SharePosterController.Action.Button.SaveImage")
        /// Share Image
        internal static let shareImage = L10n.tr("Localizable", "SharePosterController.Action.Button.ShareImage")
      }
    }
  }

  internal enum TCError {
    /// Keys already exist
    internal static let keysAlreadyExsit = L10n.tr("Localizable", "TCError.keysAlreadyExsit")
    internal enum ComposeErrorReason {
      /// Message should not be empty
      internal static let emptyInput = L10n.tr("Localizable", "TCError.ComposeErrorReason.emptyInput")
      /// No recipients available
      internal static let emptyRecipients = L10n.tr("Localizable", "TCError.ComposeErrorReason.emptyRecipients")
      /// Add recipient to send message or\nchoose your secret key to sign
      internal static let emptySenderAndRecipients = L10n.tr("Localizable", "TCError.ComposeErrorReason.emptySenderAndRecipients")
      /// Internal error
      internal static let `internal` = L10n.tr("Localizable", "TCError.ComposeErrorReason.internal")
      /// The sender does not have a valid key
      internal static let invalidSigner = L10n.tr("Localizable", "TCError.ComposeErrorReason.invalidSigner")
      /// Can't retrieve secret key from Keychain
      internal static let keychainUnlockFail = L10n.tr("Localizable", "TCError.ComposeErrorReason.keychainUnlockFail")
      /// Error Domain: %@\nCode: %@\n%@
      internal static func pgpError(_ p1: String, _ p2: String, _ p3: String) -> String {
        return L10n.tr("Localizable", "TCError.ComposeErrorReason.pgpError", p1, p2, p3)
      }
    }
    internal enum InterpretErrorReason {
      /// The message payload is invalid.\nPlease verify again
      internal static let badPayload = L10n.tr("Localizable", "TCError.InterpretErrorReason.badPayload")
      /// Message should not be empty
      internal static let emptyMessage = L10n.tr("Localizable", "TCError.InterpretErrorReason.emptyMessage")
      /// Internal Error
      internal static let `internal` = L10n.tr("Localizable", "TCError.InterpretErrorReason.internal")
      /// Can't retrieve secret key from Keychain
      internal static let keychianUnlockFailed = L10n.tr("Localizable", "TCError.InterpretErrorReason.keychianUnlockFailed")
      /// Error Domain: %@\nCode: %@\n%@
      internal static func pgpError(_ p1: String, _ p2: String, _ p3: String) -> String {
        return L10n.tr("Localizable", "TCError.InterpretErrorReason.pgpError", p1, p2, p3)
      }
    }
    internal enum PGPKeyErrorReason {
      /// The message is not signed
      internal static let failToExport = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.failToExport")
      /// Key generate fail. Please try again
      internal static let failToGenerate = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.failToGenerate")
      /// You do not have the necessary private key to decrypt this message
      internal static let failToSave = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.failToSave")
      /// Invalid Key
      internal static let invalidKeyFormat = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.invalidKeyFormat")
      /// Invalid Password
      internal static let invalidPassword = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.invalidPassword")
      /// Fail to export the key
      internal static let messageNotSigned = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.messageNotSigned")
      /// No available secret key to decrypt this message
      internal static let noAvailableDecryptKey = L10n.tr("Localizable", "TCError.PGPKeyErrorReason.noAvailableDecryptKey")
    }
    internal enum UserInfoErrorType {
      /// Invalid user name without name or email: %@
      internal static func invalidUserID(_ p1: String) -> String {
        return L10n.tr("Localizable", "TCError.UserInfoErrorType.invalidUserID", p1)
      }
    }
  }

  internal enum WizardCollectionViewController {
    internal enum Page {
      internal enum CopytoInterpret {
        /// Copy an encrypted message in a chat\nview to interpret the message. You\ncan also tap the "Key" icon in text edit\narea to interpret the text in the field.
        internal static let detailText = L10n.tr("Localizable", "WizardCollectionViewController.Page.copytoInterpret.detailText")
        /// Copy to Interpret
        internal static let titleText = L10n.tr("Localizable", "WizardCollectionViewController.Page.copytoInterpret.titleText")
      }
      internal enum ImportPublicKeys {
        /// You can import OpenPGP public keys\nby tapping "+" button in Contacts view\n and pasting in the full public key.
        internal static let detailText = L10n.tr("Localizable", "WizardCollectionViewController.Page.importPublicKeys.detailText")
        /// Import Public Keys
        internal static let titleText = L10n.tr("Localizable", "WizardCollectionViewController.Page.importPublicKeys.titleText")
      }
      internal enum TypeAndEncrypt {
        /// With Tessercube Keyboard, after\ntyping a message, you can tap the\n"tesseract" icon and select recipeints\nto encrypt for them.
        internal static let detailText = L10n.tr("Localizable", "WizardCollectionViewController.Page.typeAndEncrypt.detailText")
        /// Type and Encrypt
        internal static let titleText = L10n.tr("Localizable", "WizardCollectionViewController.Page.typeAndEncrypt.titleText")
      }
    }
  }

  internal enum WizardViewController {
    internal enum Action {
      internal enum Button {
        /// Next
        internal static let next = L10n.tr("Localizable", "WizardViewController.Action.Button.Next")
        /// Start Using
        internal static let startUsing = L10n.tr("Localizable", "WizardViewController.Action.Button.StartUsing")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
