//
//  InstagramTests.swift
//  FeedBlockerTests
//

import Testing

@Suite("Instagram content script")
struct InstagramTests {
    private let script = "instagram.js"

    @Test func hidesFeedOnHomePageByDefault() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        #expect(page.hidesFeed)
        #expect(page.redirects.isEmpty)
    }

    @Test(arguments: ["/reels", "/reels/", "/reels/abc123/", "/reel/abc123/", "/explore", "/explore/tags/cats/"])
    func redirectsBlockedRoutesHome(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.redirects == ["/"])
    }

    @Test(arguments: ["/someuser/", "/p/abc123/", "/direct/inbox/", "/reelsfan/", "/explorer/"])
    func leavesOtherPagesAlone(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.redirects.isEmpty)
        #expect(!page.hidesFeed)
    }

    @Test func blocksSinglePageNavigationToReels() throws {
        let page = try ContentScriptHarness(script: script, path: "/someuser/")

        try page.navigate(to: "/reels/abc123/")

        #expect(page.redirects == ["/"])
    }

    @Test(arguments: ["/reels/abc123/", "/reel/abc123/", "/explore/"])
    func interceptsClicksOnBlockedLinks(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: "/someuser/")

        let wasIntercepted = try page.click(path: path)

        #expect(wasIntercepted)
        #expect(page.assignments == ["/"])
    }

    @Test(arguments: ["/reelsfan/", "/explorer/", "/someuser/"])
    func doesNotInterceptOtherLinks(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        let wasIntercepted = try page.click(path: path)

        #expect(!wasIntercepted)
        #expect(page.assignments.isEmpty)
    }

    @Test func respectsDisabledPreference() throws {
        let page = try ContentScriptHarness(script: script, path: "/reels/", storage: ["enabled_instagram": false])

        #expect(page.redirects.isEmpty)
        #expect(!page.hidesFeed)
    }

    @Test func turningOffStopsBlocking() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.setStorage("enabled_instagram", to: false)
        #expect(!page.hidesFeed)
        #expect(page.historyIsUnhooked)
        #expect(page.activeIntervalCount == 0)

        try page.navigate(to: "/reels/abc123/")
        #expect(page.redirects.isEmpty)

        let wasIntercepted = try page.click(path: "/reels/abc123/")
        #expect(!wasIntercepted)
    }

    @Test func turningBackOnDoesNotDuplicateWatchers() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.setStorage("enabled_instagram", to: false)
        try page.setStorage("enabled_instagram", to: true)

        #expect(page.hidesFeed)
        #expect(page.activeIntervalCount == 1)
        #expect(page.activeObserverCount == 1)
    }
}
