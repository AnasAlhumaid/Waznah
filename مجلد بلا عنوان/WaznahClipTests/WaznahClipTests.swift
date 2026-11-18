//
//  WaznahClipTests.swift
//  WaznahClipTests
//
//  Created by Anas Hamad on 14/10/2026.
//

import Testing
@testable import WaznahClip

struct WaznahClipTests {
    /// Real share link. The id is percent-encoded base64 and must survive storage and opening.
    private let sample = "https://share-h5.xbloom.com/?id=9EvH9mTldI3NaCM1NJX%2FCw%3D%3D"

    @Test func sampleLinkIsKeptExactly() {
        #expect(XBloomShareLink.preserved(sample) == sample)
        #expect(XBloomShareLink.preserved("  \(sample)\n") == sample)

        let link = XBloomShareLink.link(from: sample)
        #expect(link?.exact == sample)
        let absolute = link?.url.absoluteString ?? ""
        #expect(absolute.contains("id=9EvH9mTldI3NaCM1NJX%2FCw%3D%3D"))
        #expect(!absolute.contains("%252F"))
        #expect(!absolute.contains("%253D"))
        #expect(!absolute.contains("NJX/Cw"))
    }

    @Test func rejectsUnofficialHosts() {
        #expect(XBloomShareLink.preserved("https://xbloom.com/?id=abc") == nil)
        #expect(XBloomShareLink.preserved("https://evil.xbloom.com/?id=abc") == nil)
        #expect(XBloomShareLink.preserved("https://share-h5.xbloom.com.evil.com/?id=abc") == nil)
        #expect(XBloomShareLink.preserved("http://share-h5.xbloom.com/?id=abc") == nil)
        #expect(XBloomShareLink.preserved("https://share-h5.xbloom.com/path?id=abc") == nil)
        #expect(XBloomShareLink.preserved("https://share-h5.xbloom.com/?id=") == nil)
        #expect(XBloomShareLink.preserved("https://share-h5.xbloom.com/?id=abc def") == nil)
        #expect(XBloomShareLink.preserved(nil) == nil)
        #expect(XBloomShareLink.preserved("   ") == nil)
    }

    @Test func missingFieldsMeanNoLink() throws {
        let model = try JSONDecoder().decode(YourDataModelRes.self, from: Data("{}".utf8))
        #expect(model.xbloomURL == nil)
        #expect(model.xbloomStudioURL == nil)
        #expect(model.xbloomOriginalURL == nil)
        #expect(model.xbloomLinks.choices.isEmpty)
    }

    @Test func deviceLinksAndLegacyDecodeExactly() throws {
        let studio = sample
        let original = "https://share-h5.xbloom.com/?id=original%2Bid"
        let json = """
        {"xbloomStudioURL":"\(studio)","xbloomOriginalURL":"\(original)","xbloomURL":"\(studio)"}
        """
        let model = try JSONDecoder().decode(YourDataModelRes.self, from: Data(json.utf8))
        #expect(model.xbloomStudioURL == studio)
        #expect(model.xbloomOriginalURL == original)
        #expect(model.xbloomLinks.choices.count == 2)
        #expect(model.xbloomLinks.choices.first?.device == .studio)
        #expect(model.xbloomLinks.choices.first?.exact == studio)
        #expect(model.xbloomLinks.choices.last?.device == .original)
        #expect(model.xbloomLinks.choices.last?.exact == original)

        let legacy = try JSONDecoder().decode(
            YourDataModelRes.self,
            from: Data("{\"xbloomURL\":\"\(studio)\"}".utf8)
        )
        #expect(legacy.xbloomLinks.choices.count == 1)
        #expect(legacy.xbloomLinks.choices.first?.device == nil)
        #expect(legacy.xbloomLinks.choices.first?.exact == studio)

        let bogus = try JSONDecoder().decode(
            YourDataModelRes.self,
            from: Data("{\"xbloomStudioURL\":\"https://example.com/?id=1\"}".utf8)
        )
        #expect(bogus.xbloomStudioURL == "https://example.com/?id=1")
        #expect(bogus.xbloomLinks.choices.isEmpty)
    }
}
