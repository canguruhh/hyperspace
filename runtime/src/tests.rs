#![cfg(test)]

use super::*;
use mock::*;

pub const ETP: CurrencyId = CurrencyId::ETP;
pub const CUSDT: CurrencyId = CurrencyId::CUSDT;

#[test]
fn test_balance() {
  ExtBuilder::default()
    .balances(vec![
      (AccountId::from(ALICE), ETP, 1000),
      (AccountId::from(BOB), CUSDT, 1000),
    ])
    .build()
    .execute_with(|| {
      assert_eq!(<Currencies as MultiCurrency<_>>::free_balance(ETP, &AccountId::from(ALICE)), 500);
      assert_eq!(<Currencies as MultiCurrency<_>>::free_balance(CUSDT, &AccountId::from(BOB)), 1000);

      let _ = <Currencies as MultiCurrencyExtended<_>>::update_balance(ETP, &AccountId::from(ALICE), 1000);
      assert_eq!(<Currencies as MultiCurrency<_>>::free_balance(ETP, &AccountId::from(ALICE)), 1500);
    });
}
