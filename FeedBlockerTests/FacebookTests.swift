//
//  FacebookTests.swift
//  FeedBlockerTests
//

import Testing

@Suite("Facebook content script")
struct FacebookTests {
    private let script = "facebook.js"

    @Test func hidesFeedOnHomePageByDefault() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        #expect(page.hidesFeed)
        #expect(page.redirects.isEmpty)
    }

    @Test(arguments: ["/watch", "/watch/", "/watch/live/", "/reel/123456", "/reels", "/reels/"])
    func redirectsBlockedRoutesHome(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.redirects == ["/"])
    }

    @Test(arguments: ["/someone", "/groups/123/", "/marketplace/", "/messages/t/123", "/watchparty.fan"])
    func leavesOtherPagesAlone(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.redirects.isEmpty)
        #expect(!page.hidesFeed)
    }

    @Test func followsSinglePageNavigation() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.navigate(to: "/groups/123/")
        #expect(!page.hidesFeed)

        try page.navigate(to: "/watch/")
        #expect(page.redirects == ["/"])
    }

    @Test(arguments: ["/watch/", "/reel/123456", "/reels/"])
    func interceptsClicksOnBlockedLinks(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: "/groups/123/")

        let wasIntercepted = try page.click(path: path)

        #expect(wasIntercepted)
        #expect(page.assignments == ["/"])
    }

    @Test func respectsDisabledPreference() throws {
        let page = try ContentScriptHarness(script: script, path: "/watch/", storage: ["enabled_facebook": false])

        #expect(page.redirects.isEmpty)
        #expect(!page.hidesFeed)
    }

    @Test func turningOffStopsBlocking() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.setStorage("enabled_facebook", to: false)
        #expect(!page.hidesFeed)

        try page.navigate(to: "/")
        #expect(!page.hidesFeed)
    }
}
