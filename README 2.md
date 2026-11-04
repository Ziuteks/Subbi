# SubscriptionTracker

Prosty startowy projekt iOS w SwiftUI do zarządzania subskrypcjami.

## Wymagania
- macOS + Xcode 15 lub nowszy
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Uruchomienie
1. W terminalu przejdź do katalogu projektu.
2. Wygeneruj projekt Xcode: `xcodegen generate`
3. Otwórz `SubscriptionTracker.xcodeproj`.
4. Wybierz symulator i uruchom aplikację (`⌘R`).

## Co jest w szkielecie
- lista subskrypcji z przykładowymi danymi,
- suma miesięcznych kosztów,
- dodawanie subskrypcji,
- prosty model danych i osobny store,
- SwiftUI + MVVM-ish separation.

Na start dane są przechowywane tylko w pamięci — po ponownym uruchomieniu aplikacji wrócą dane przykładowe. Następny krok: trwały zapis (SwiftData), edycja/usuwanie, przypomnienia i kategorie.

## Git
```bash
git init
git add .
git commit -m "chore: initial SwiftUI subscription tracker scaffold"
```
