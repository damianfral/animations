module Main where

import Animations
import Animations.Copy
import Animations.IO

import Control.Applicative
import Control.Concurrent


runI :: (Show a) => Behavior Identity a -> IO ()
runI (a `AndThen` as) = do
  runI (runIdentity as)

runC :: (Show a) => Behavior Copy a -> IO ()
runC (_ `AndThen` as) = do
  runC (getCopy as)

runBehaviorTiming :: (Show a) => Behavior IO a -> IO ()
runBehaviorTiming (a `AndThen` nextBehavior) = do
  before <- getCurrentTime
  print a
  behavior' <- nextBehavior
  after <- getCurrentTime
  putStrLn ("TIME: " ++ show (diffUTCTime after before))
  runBehaviorTiming behavior'

runBehavior :: (Show a) => Behavior Next a -> IO ()
runBehavior (_ `AndThen` nextBehavior) = do
  -- print a
  behavior' <- runNext nextBehavior
  runBehavior behavior'



buffer ::
  (Functor next) =>
  Int ->
  Behavior next Int ->
  Behavior next Int
buffer n (x `AndThen` nextXs) =
  n `AndThen` fmap (buffer x) nextXs

forward ::
  (Functor next) =>
  Behavior next Int ->
  next (Behavior next Int)
forward (x `AndThen` nextXs) =
  fmap (buffer x) nextXs

scary_const ::
  (Functor next) =>
  Behavior next Int ->
  Behavior next (Behavior next Int)
scary_const xs =
  xs `AndThen` fmap scary_const (forward xs)

scary_const_example :: IO ()
scary_const_example = do

  let numbers = countFrom 0

  let scary_const_numbers = fmap now (scary_const numbers)

  let pairs = liftA2 (,) numbers scary_const_numbers

  runCopying pairs


integral ::
  (Applicative next) =>
  Double ->
  Behavior next Double ->
  Behavior next Double
integral x (v `AndThen` nextVs) =
  x `AndThen` (fmap (integral (x + v)) nextVs)


e_example :: IO ()
e_example = do

  let e = integral 1 (1 `AndThen` pure e)

  runList e


count_example :: IO ()
count_example = runBehavior count

diagonal_example :: IO ()
diagonal_example = runBehavior (fmap now (diagonal count))

always_example :: IO ()
always_example = runBehavior always5

test_example :: IO ()
test_example = do
  event <- runNext (test 1100000)
  runEvent event

diagonal :: Behavior Next Int -> Behavior Next (Behavior Next Int)
diagonal ns = ns `AndThen` fmap diagonal (future ns)

count :: Behavior Next Int
count = go 0 where
  go i = i `AndThen` pure (go (i+1))

always5 :: Behavior Next Double
always5 = 5 `AndThen` (pure always5)


test :: Int -> Next (Event Next ())
test _ = undefined
  -- fmap (\b -> pure (whenTrue ((n ==) <$> b))) count'

count' :: Next (Behavior Next Int)
count' = undefined{-loop 0 where
  loop i = do
    e <- async (return ())
    e' <- plan (loop (i + 1) <$ e)
    return (pure i `switch` e')-}

async :: IO a -> Next (Event Next a)
async action = syncIO (do
  mvar <- newEmptyMVar
  _ <- forkIO (action >>= putMVar mvar)
  let nextEvent = syncIO (do
        maybeValue <- tryTakeMVar mvar
        case maybeValue of
          Nothing -> pure (Later nextEvent)
          Just value -> pure (Occured value))
  runNext nextEvent)



















{-
mainProgram = do
>     render (Color white $ Scale 0.2 0.2 $ Text "Type some text")


>     forM_ [780, 760..] $ \ypos -> do
>         forM_ [0, 20..980] $ \xpos -> do



>             event <- iterateUntil keydown $ input



>             let key = case event of
>                         EventKey (Char key)            Down _ _ -> key
>                         EventKey (SpecialKey KeySpace) Down _ _ -> ' '



>             when (ypos == 780 && xpos == 0) $ cls
>             render $ Color white $ Translate (xpos-500) (ypos-400) $ Scale 0.2 0.2 $ Text $ [key]
-}




