defmodule Bookshelf.PubSubs.ImportBook do
  @topic inspect(__MODULE__)

  def notify_new_job(filename) do
    Phoenix.PubSub.broadcast(Bookshelf.PubSub, @topic, {:new_job, filename})
  end

  def notify_end_of_job(filename) do
    Phoenix.PubSub.broadcast(Bookshelf.PubSub, @topic, {:end_of_job, filename})
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Bookshelf.PubSub, @topic)
  end
end
