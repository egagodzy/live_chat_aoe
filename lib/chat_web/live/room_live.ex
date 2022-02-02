defmodule ChatWeb.RoomLive do
 use ChatWeb, :live_view
 require Logger
 import Phoenix.LiveView.Helpers

 @impl true
 def mount(%{"id" => room_id}, _session, socket) do
   topic = "room:" <> room_id
   username = MnemonicSlugs.generate_slug(2)

   if connected?(socket) do
     ChatWeb.Endpoint.subscribe(topic)
     ChatWeb.Presence.track(self(), topic, username, %{})
   end

   {:ok,
    assign(socket,
     room_id: room_id,
     topic: topic,
     username: username,
     message: "",
     messages: [],
     user_list: [],
     temporary_assigns: [messages: []]
    )}
 end

 @impl true
 def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
   Logger.info(message: message)
   message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
   ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
   {:noreply, assign(socket, message: "")}
 end

 @impl true
 def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
   {:noreply, assign(socket, message: message)}
 end

 @impl true
 def handle_info(%{event: "new-message", payload: message}, socket) do
   Logger.info(payload: message)
   {:noreply, assign(socket, messages: [message])}
 end

 @impl true
 def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
   join_messages = 
    joins
     |> Map.keys()
     |> Enum.map(fn username ->
     %{uuid: UUID.uuid4(), content: "#{username} присоеденился к чату", username: "system"}
   end)

   leave_messages = 
    leaves
     |> Map.keys()
     |> Enum.map(fn username ->
     %{uuid: UUID.uuid4(), content: "#{username} покинул", username: "system"}
   end)

   user_list =
    ChatWeb.Presence.list(socket.assigns.topic)
    |> Map.keys()

   {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
 end

end