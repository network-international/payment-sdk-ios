//
//  KeyboardDismissalTests.swift
//  NISdkTests
//
//  A number pad has no Return key, so a CVV field using one traps the user
//  unless the SDK supplies its own way out: a Done bar over the keyboard and a
//  tap outside the field. These cover both, and the helper that scrolls the
//  focused field back above the keyboard.
//

import XCTest
@testable import NISdk

final class KeyboardDismissalTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        // First-responder status only takes effect inside a visible window.
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    private func doneItem(of field: UITextField) -> UIBarButtonItem? {
        return (field.inputAccessoryView as? UIToolbar)?.items?.last
    }

    // MARK: - Done accessory

    func testAccessoryIsAToolbarWithADoneButton() {
        let field = UITextField()
        field.addNumericDoneAccessory()

        let toolbar = field.inputAccessoryView as? UIToolbar
        XCTAssertNotNil(toolbar, "numeric fields need an accessory bar — the pad has no Return key")
        XCTAssertEqual(toolbar?.items?.count, 2)
        XCTAssertEqual(doneItem(of: field)?.title, "Done".localized)
        XCTAssertEqual(doneItem(of: field)?.accessibilityIdentifier, "sdk_keyboard_button_done")
    }

    func testDoneButtonTargetsTheFieldAndResignsIt() {
        let field = UITextField()
        window.addSubview(field)
        field.addNumericDoneAccessory()

        guard let done = doneItem(of: field), let action = done.action else {
            return XCTFail("no Done item")
        }
        XCTAssertTrue(done.target as AnyObject? === field,
                      "the Done button must act on its own field, not on a shared handler")

        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(field.isFirstResponder)
        _ = (done.target as AnyObject?)?.perform(action)
        XCTAssertFalse(field.isFirstResponder, "tapping Done should dismiss the keyboard")
    }

    func testNiDismissKeyboardResignsFirstResponder() {
        let field = UITextField()
        window.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())

        field.niDismissKeyboard()

        XCTAssertFalse(field.isFirstResponder)
    }

    // MARK: - Tap to dismiss

    func testTapToDismissAddsANonSwallowingRecogniser() {
        let view = UIView()
        XCTAssertNil(view.gestureRecognizers)

        view.addTapToDismissKeyboard()

        let tap = view.gestureRecognizers?.first as? UITapGestureRecognizer
        XCTAssertNotNil(tap)
        XCTAssertFalse(tap?.cancelsTouchesInView ?? true,
                       "the dismissing tap must still reach the Pay button underneath")
    }

    func testTapActionEndsEditingInTheSubtree() {
        let container = UIView(frame: window.bounds)
        let field = UITextField()
        container.addSubview(field)
        window.addSubview(container)
        container.addTapToDismissKeyboard()

        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertNotNil(container.gestureRecognizers?.first as? UITapGestureRecognizer)
        container.niEndEditing()

        XCTAssertFalse(field.isFirstResponder)
    }

    // MARK: - Finding the focused field

    func testFirstResponderIsFoundThroughNestedSubviews() {
        let outer = UIView(frame: window.bounds)
        let inner = UIView()
        let field = UITextField()
        inner.addSubview(field)
        outer.addSubview(inner)
        window.addSubview(outer)

        XCTAssertNil(outer.niFirstResponder, "nothing is focused yet")

        XCTAssertTrue(field.becomeFirstResponder())

        XCTAssertTrue(outer.niFirstResponder === field,
                      "the scroll view must find the focused field however deeply it is nested")
    }

    func testFirstResponderIsTheViewItselfWhenItHasFocus() {
        let field = UITextField()
        window.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())

        XCTAssertTrue(field.niFirstResponder === field)
    }
}
