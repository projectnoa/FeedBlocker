//
//  YouTubeTests.swift
//  FeedBlockerTests
//

import Testing

@Suite("YouTube content script")
struct YouTubeTests {
    private let script = "youtube.js"

    @Test func hidesFeedOnHomePageByDefault() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        #expect(page.hidesFeed)
    }

    @Test(arguments: ["/watch", "/results", "/feed/subscriptions", "/@somechannel"])
    func leavesOtherPagesVisible(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(!page.hidesFeed)
        #expect(page.redirects.isEmpty)
    }

    /// Shorts and recommendation rules in youtube.css are keyed off `no-recs`, which must stay on everywhere.
    @Test(arguments: ["/", "/watch", "/results"])
    func hidesShortsAndRecommendationsOnEveryPage(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.hasClass("no-recs"))
    }

    @Test(arguments: ["/shorts", "/shorts/abc123"])
    func redirectsShortsHome(path: String) throws {
        let page = try ContentScriptHarness(script: script, path: path)

        #expect(page.redirects == ["/"])
    }

    @Test func interceptsClicksOnShortsLinks() throws {
        let page = try ContentScriptHarness(script: script, path: "/results")

        let wasIntercepted = try page.click(path: "/shorts/abc123")

        #expect(wasIntercepted)
        #expect(page.assignments == ["/"])
    }

    @Test func respectsDisabledPreference() throws {
        let page = try ContentScriptHarness(script: script, path: "/shorts/abc123", storage: ["enabled_youtube": false])

        #expect(!page.hidesFeed)
        #expect(!page.hasClass("no-recs"))
        #expect(page.redirects.isEmpty)
        #expect(page.historyIsUnhooked)
        #expect(page.activeIntervalCount == 0)
    }

    @Test func followsSinglePageNavigation() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.navigate(to: "/watch")
        #expect(!page.hidesFeed)

        try page.popState(to: "/")
        #expect(page.hidesFeed)
    }

    @Test func turningOffRestoresPageAndStopsWatching() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.setStorage("enabled_youtube", to: false)

        #expect(!page.hidesFeed)
        #expect(!page.hasClass("no-recs"))
        #expect(page.historyIsUnhooked)
        #expect(page.activeIntervalCount == 0)
        #expect(page.activeObserverCount == 0)

        try page.navigate(to: "/")
        #expect(!page.hidesFeed)
    }

    @Test func turningBackOnDoesNotDuplicateWatchers() throws {
        let page = try ContentScriptHarness(script: script, path: "/")

        try page.setStorage("enabled_youtube", to: false)
        try page.setStorage("enabled_youtube", to: true)

        #expect(page.hidesFeed)
        #expect(page.activeIntervalCount == 1)
        #expect(page.activeObserverCount == 1)
    }
}
