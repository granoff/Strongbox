import UIKit
import XCTest
import Strongbox

class Tests: XCTestCase {
    
    let testString = "TestString"
    let testArray = [ "A", "B", "C"]
    let testDictionary = [ "Key 1": "A",
                           "Key 2": "B",
                           "Key 3": "C" ]
    let testDate = NSDate()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testArchiveObject() {
        let sb = Strongbox()
        let valueToStore = "Foobar"
        XCTAssertTrue(sb.archive(valueToStore, key:"TestKey"))
        
        let storedValue = sb.unarchive(objectForKey: "TestKey") as! String
        XCTAssertTrue(valueToStore == storedValue, "stored value (\(storedValue)) does not equal value stored (\(valueToStore))")
        
    }

    func testHierarchicalKeyNoPrefix() {
        let prefix = Bundle.main.bundleIdentifier!
        let key = "TestKey"
        let sb = Strongbox()
        let expectedKey = prefix + "." + key
        XCTAssertTrue(sb.hierarchicalKey(key) == expectedKey, "hierarchicalKey failed to generate \(expectedKey)")
    }
    
    func testHierarchicalKeyWithPrefix() {
        let prefix = "TestPrefix"
        let key = "TestKey"
        let sb = Strongbox(keyPrefix: prefix)
        let expectedKey = prefix + "." + key
        XCTAssertTrue(sb.hierarchicalKey(key) == expectedKey, "hierarchicalKey failed to generate \(expectedKey)")
    }
    
    func testArchiveStringForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestStringKey"
        XCTAssertTrue(subject.archive(testString, key: key), "Should be able to archive a string")
        XCTAssertEqual(subject.unarchive(objectForKey: key) as! String, testString, "Retrieved string should match original")
    }
    
    func testDeleteStringForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestStringKey"
        XCTAssertTrue(subject.archive(testString, key: key), "Should be able to archive a string")
        XCTAssertEqual(subject.unarchive(objectForKey: key) as! String, testString, "Retrieved string should match original")
        XCTAssertTrue(subject.archive(nil, key: key), "Should be able to set string for key to nil")
        XCTAssertNil(subject.unarchive(objectForKey: key), "Deleted key should return nil")
    }
    
    func testSetArrayForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestArrayKey"
        XCTAssertTrue(subject.archive(testArray, key: key), "Should be able to store an array")
        let object:Any = subject.unarchive(objectForKey: key)!
        guard let array=object as? Array<String> else {
            XCTFail("Failed to retrieve Array<String> object")
            return
        }
        XCTAssertTrue(testArray.elementsEqual(array), "Retrieved array should match original")
    }
    
    func testSetSetForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestSetKey"
        let testSet = NSSet(array: testArray)
        XCTAssertTrue(subject.archive(testSet, key: key), "Should be able to store a set")
        let object:Any = subject.unarchive(objectForKey: key)
        guard let set=object as? Set<String> else {
            XCTFail("Failed to retrieve Set<String> object")
            return
        }
        XCTAssertTrue(testSet.isEqual(set), "Retrieved set should match original")
    }
    
    func testSetDictionaryForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestDictionaryKey"
        XCTAssertTrue(subject.archive(testDictionary, key: key), "Should be able to store a dictionary")
        let object:Any = subject.unarchive(objectForKey: key)
        guard let dict=object as? Dictionary<String,String> else {
            XCTFail("Failed to retrieve Dictionary<String,String> object")
            return
        }
        XCTAssertEqual(testDictionary as Dictionary<String,String>, dict as Dictionary<String,String>, "Retrieved dictionary should match original")
        
        let expectedValueForKey = testDictionary["Key 1"]
        let actualValueForKey = dict["Key 1"]
        XCTAssertEqual(expectedValueForKey, actualValueForKey, "Actual objectForKey value doesn't match expected value")
    }
    
    func testSetSameKeyWithTwoValue() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestKey"
        XCTAssertTrue(subject.archive("1", key: key), "Set '1' for key \(key)")
        XCTAssertTrue("1" == subject.unarchive(objectForKey: key) as? String, "Retrieve '1' for key \(key)")
        XCTAssertTrue(subject.archive("2", key: key), "Set '2' for key \(key)")
        XCTAssertTrue("2" == subject.unarchive(objectForKey: key) as? String, "Retrieve '2' for key \(key)")
    }
    
    func testSetDateForKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestDateKey"
        XCTAssertTrue(subject.archive(testDate, key: key), "Should be able to store a date")
        let object:Any = subject.unarchive(objectForKey: key)
        guard let date=object as? NSDate else {
            XCTFail("Failed to retrieve NSDate object")
            return
        }
        XCTAssertEqual(testDate, date, "Retrieved date should match original")

        XCTAssertTrue(subject.archive(nil, key: key), "Should be able to remove a stored date")
    }
    
    func testSetNilForNoKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestFakeKey"
        XCTAssertTrue(subject.archive(nil, key: key), "Should be able to try to remove the value for a non-existent key")
    }
    
    func testRetrieveForNoKey() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestFakeKey"
        XCTAssertNil(subject.unarchive(objectForKey: key), "Should return nil for non-existent key")
    }
    
    func testArrayOfDictionary() {
        let subject = Strongbox(keyPrefix: "StrongBoxTests")
        let key = "TestArrayOfDictKey"
        let subjectArray = [ testDictionary ]
        XCTAssertTrue(subject.archive(subjectArray, key: key), "Should be able to store Array<Dictionary>")
        
        let object:Any = subject.unarchive(objectForKey: key)!
        guard let array=object as? Array<Dictionary<String,String>> else {
            XCTFail("Failed to retrieve Array<Dictionary> object")
            return
        }
        
        XCTAssertTrue(array.count == subjectArray.count, "Retrieved array<dictionary> should be same size as original")
        let dict = array.first! as Dictionary<String,String>
        XCTAssertTrue(testDictionary == dict, "Retrieved embedded dictionary should equal original embedded dictionary")
        
    }
}
