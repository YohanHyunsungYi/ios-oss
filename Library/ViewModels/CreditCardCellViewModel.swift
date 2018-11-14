import KsApi
import Prelude
import ReactiveSwift
import ReactiveExtensions
import Result
import UIKit

public protocol CreditCardCellViewModelInputs {
  /// Call to configure cell with card value.
  func configureWith(creditCard: GraphUserCreditCard.CreditCard)
}

public protocol CreditCardCellViewModelOutputs {
  /// Emits the card's image.
  var cardImage: Signal<UIImage?, NoError> { get }

  /// Emits a formatted string containing the card's last four digits.
  var cardNumberText: Signal<String, NoError> { get }

  /// Emits the formatted card's expirationdate.
  var expirationDateText: Signal<String, NoError> { get }
}

public protocol CreditCardCellViewModelType {
  var inputs: CreditCardCellViewModelInputs { get }
  var outputs: CreditCardCellViewModelOutputs { get }
}

public final class CreditCardCellViewModel: CreditCardCellViewModelInputs,
CreditCardCellViewModelOutputs, CreditCardCellViewModelType {

  public init() {

    self.cardImage = self.cardProperty.signal.skipNil()
      .map(cardImage(with:))

    self.cardNumberText = self.cardProperty.signal.skipNil()
      .map { Strings.Card_ending_in_last_four(last_four: $0.lastFour) }

    self.expirationDateText = self.cardProperty.signal.skipNil()
      .map { Strings.Credit_card_expiration(
        expiration_date: formatted(dateString: $0.formattedExpirationDate)
        )
    }
  }

  fileprivate let cardProperty = MutableProperty<GraphUserCreditCard.CreditCard?>(nil)
  public func configureWith(creditCard: GraphUserCreditCard.CreditCard) {
    self.cardProperty.value = creditCard
  }

  public let cardImage: Signal<UIImage?, NoError>
  public let expirationDateText: Signal<String, NoError>
  public let cardNumberText: Signal<String, NoError>

  public var inputs: CreditCardCellViewModelInputs { return self }
  public var outputs: CreditCardCellViewModelOutputs { return self }
}

private func cardImage(with card: GraphUserCreditCard.CreditCard) -> UIImage? {
  return image(named: "icon--" + card.type.rawValue.lowercased()) ?? image(named: "icon--generic")
}

private func formatted(dateString: String) -> String {
  let date = toDate(dateString: dateString)
  return Format.date(secondsInUTC: date.timeIntervalSince1970, template: "MM-yyyy")
}

private func toDate(dateString: String) -> Date {
  // Always use UTC timezone here this date should be timezone agnostic
  guard let date = Format.date(from: dateString,
                               dateFormat: "yyyy-MM",
                               timeZone: UTCTimeZone) else {
    fatalError("Unable to parse date format")
  }

  return date
}
