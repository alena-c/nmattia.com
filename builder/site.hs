--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Control.Monad (forM_)
import Hakyll
import Hakyll.Web.Pandoc (pandocCompiler)
import System.FilePath  (joinPath, splitPath)

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "nmattia's blog"
    , feedDescription = "Experiments with software"
    , feedAuthorName  = "Nicolas Mattia"
    , feedAuthorEmail = "nicolas@nmattia.com"
    , feedRoot        = "http://www.nmattia.com"
    }

main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/default.css" $ do
        route   idRoute
        compile compressCssCompiler

    match "css/font-awesome/**/*" $ do
        route idRoute
        compile copyFileCompiler

    match (fromList ["blog.md", "about.md", "index.md"]) $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

    match ("posts/*.md" .||. "posts/*.lhs") $ do
        route $ setExtension "html"
        compile $ pandocCompiler
              >>= saveSnapshot "content"
              >>= loadAndApplyTemplate "templates/default.html" defaultContext
              >>= relativizeUrls

    create ["atom.xml"] $ do
      route idRoute
      compile $ do
          let feedCtx = postCtx `mappend` bodyField "description"
          posts <- fmap (take 10) . recentFirst =<<
                   loadAllSnapshots "posts/*" "content"
          renderAtom myFeedConfiguration feedCtx posts

    create ["rss.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <- fmap (take 10) . recentFirst =<<
                 loadAllSnapshots "posts/*" "content"
        renderAtom myFeedConfiguration feedCtx posts

    match "material/index.html" $ do
        route idRoute
        compile copyFileCompiler
    match "material/**/*" $ do
        route idRoute
        compile copyFileCompiler

    match "icons/*" $ do
        route dropIconsRoute
        compile copyFileCompiler

    forM_ [ "resume.pdf"
          , "resume.html"
          , "parallel-dna.pdf"
          , "regular-strands.pdf"
          , "schroedinger.pdf"
          , "stone-age.pdf"
          ]
          (\f -> match f (route idRoute >> compile copyFileCompiler))

--------------------------------------------------------------------------------
-- | Drop the `icons/` part from a route.
dropIconsRoute :: Routes
dropIconsRoute = customRoute $ \ident ->
    let path0 = toFilePath ident in
    case splitPath path0 of
        "icons/" : path1 -> joinPath path1
        _                  -> path0

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
