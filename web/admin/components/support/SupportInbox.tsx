'use client';

import { useEffect, useState, useRef } from 'react';
import { createClient } from '@/lib/supabase/client';
import {
  fetchSupportConversations,
  fetchConversationMessages,
  sendAdminSupportMessage,
  updateConversationStatus,
  type SupportConversation,
  type SupportMessage,
} from '@/lib/support';
import { MessageSquare, Phone, Send } from 'lucide-react';

export default function SupportInbox() {
  const [conversations, setConversations] = useState<SupportConversation[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [messages, setMessages] = useState<SupportMessage[]>([]);
  const [inputMessage, setInputMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'open' | 'closed'>('all');

  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load conversations
  useEffect(() => {
    async function load() {
      try {
        const data = await fetchSupportConversations();
        setConversations(data);
        if (data.length > 0 && !selectedId) {
          setSelectedId(data[0].id);
        }
      } finally {
        setLoading(false);
      }
    }
    load();

    // Subscribe to conversations realtime
    const supabase = createClient();
    const convChannel = supabase
      .channel('realtime:support_conversations')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'support_conversations' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setConversations((prev) => [payload.new as SupportConversation, ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            setConversations((prev) =>
              prev.map((c) => (c.id === payload.new.id ? (payload.new as SupportConversation) : c))
            );
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(convChannel);
    };
  }, []);

  // Load messages when selectedId changes
  useEffect(() => {
    if (!selectedId) return;

    let active = true;
    async function loadMessages() {
      const msgs = await fetchConversationMessages(selectedId!);
      if (active) {
        setMessages(msgs);
        scrollToBottom();
      }
    }
    loadMessages();

    // Subscribe to messages in this conversation
    const supabase = createClient();
    const msgChannel = supabase
      .channel(`realtime:support_messages:${selectedId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'support_messages',
          filter: `conversation_id=eq.${selectedId}`,
        },
        (payload) => {
          setMessages((prev) => {
            if (prev.some((m) => m.id === payload.new.id)) return prev;
            return [...prev, payload.new as SupportMessage];
          });
          scrollToBottom();
        }
      )
      .subscribe();

    return () => {
      active = false;
      supabase.removeChannel(msgChannel);
    };
  }, [selectedId]);

  const scrollToBottom = () => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleSend = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!selectedId || !inputMessage.trim() || sending) return;

    const content = inputMessage.trim();
    setInputMessage('');
    setSending(true);

    try {
      const newMsg = await sendAdminSupportMessage(selectedId, content, 'Supermarket Support');
      if (newMsg) {
        setMessages((prev) => [...prev, newMsg]);
        scrollToBottom();
      }
    } catch (err) {
      alert(`Failed to send message: ${err}`);
    } finally {
      setSending(false);
    }
  };

  const handleQuickReply = (text: string) => {
    setInputMessage(text);
  };

  const handleToggleStatus = async (conv: SupportConversation) => {
    const nextStatus = conv.status === 'open' ? 'closed' : 'open';
    await updateConversationStatus(conv.id, nextStatus);
    setConversations((prev) =>
      prev.map((c) => (c.id === conv.id ? { ...c, status: nextStatus } : c))
    );
  };

  const filteredConversations = conversations.filter((c) => {
    if (filter === 'open') return c.status === 'open';
    if (filter === 'closed') return c.status === 'closed';
    return true;
  });

  const selectedConv = conversations.find((c) => c.id === selectedId);

  return (
    <div className="h-[calc(100vh-140px)] flex flex-col bg-white border border-gray-200 rounded-2xl shadow-xs overflow-hidden">
      {/* Top Header */}
      <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-slate-50/50">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-quickopia-navy flex items-center justify-center text-white shadow-xs">
            <MessageSquare className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-lg font-black text-slate-900 tracking-tight flex items-center gap-2">
              Customer Support Desk & Messenger
              <span className="text-[11px] font-bold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full">
                Live Supabase Realtime
              </span>
            </h1>
            <p className="text-xs text-gray-500">
              Direct real-time two-way messaging with shoppers in Dar es Salaam — zero third-party subscription fees.
            </p>
          </div>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 bg-gray-200/60 p-1 rounded-xl text-xs font-bold">
          {(['all', 'open', 'closed'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg capitalize transition ${
                filter === f
                  ? 'bg-white text-quickopia-navy shadow-xs'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {f === 'all' ? 'All Inquiries' : f}
            </button>
          ))}
        </div>
      </div>

      {/* Main Workspace: Left Conversations List + Right Chat Box */}
      <div className="flex-1 flex min-h-0">
        {/* Left List */}
        <div className="w-80 md:w-96 border-r border-gray-200 flex flex-col bg-gray-50/50">
          <div className="p-3 border-b border-gray-200 bg-white">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">
              Conversations ({filteredConversations.length})
            </span>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-gray-100">
            {loading ? (
              <div className="p-8 text-center text-gray-400 text-xs">Loading conversations...</div>
            ) : filteredConversations.length === 0 ? (
              <div className="p-8 text-center text-gray-400 text-xs">
                No conversations found in this filter.
              </div>
            ) : (
              filteredConversations.map((conv) => {
                const isSelected = conv.id === selectedId;
                return (
                  <button
                    key={conv.id}
                    onClick={() => setSelectedId(conv.id)}
                    className={`w-full text-left p-3.5 transition flex items-start gap-3 ${
                      isSelected
                        ? 'bg-quickopia-navy/5 border-l-4 border-quickopia-navy'
                        : 'hover:bg-gray-100/70'
                    }`}
                  >
                    <div className="w-9 h-9 rounded-full bg-slate-200 flex items-center justify-center font-bold text-slate-700 text-xs shrink-0">
                      {conv.customer_name?.charAt(0) || 'S'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-1 mb-0.5">
                        <span className="text-xs font-bold text-slate-900 truncate">
                          {conv.customer_name || 'Customer'}
                        </span>
                        <span
                          className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${
                            conv.status === 'open'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-gray-200 text-gray-700'
                          }`}
                        >
                          {conv.status}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 truncate">
                        {conv.last_message || 'New customer inquiry started'}
                      </p>
                      {conv.customer_phone && (
                        <span className="text-[10px] text-gray-400 flex items-center gap-1 mt-0.5">
                          <Phone className="w-3 h-3 text-gray-400 inline" /> {conv.customer_phone}
                        </span>
                      )}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Right Active Chat Pane */}
        {selectedConv ? (
          <div className="flex-1 flex flex-col min-w-0 bg-white">
            {/* Conversation Header */}
            <div className="px-6 py-3 border-b border-gray-200 flex items-center justify-between bg-white">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-quickopia-amber/20 flex items-center justify-center font-bold text-amber-800 text-xs">
                  {selectedConv.customer_name?.charAt(0) || 'S'}
                </div>
                <div>
                  <h2 className="text-sm font-bold text-slate-900">
                    {selectedConv.customer_name || 'Customer'}
                  </h2>
                  <div className="text-[11px] text-gray-500 flex items-center gap-2">
                    {selectedConv.customer_phone && (
                      <span className="flex items-center gap-1">
                        <Phone className="w-3 h-3 text-gray-400 inline" /> {selectedConv.customer_phone}
                      </span>
                    )}
                    <span>•</span>
                    <span className="text-emerald-600 font-semibold">Live Realtime Active</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => handleToggleStatus(selectedConv)}
                  className={`text-xs font-bold px-3 py-1.5 rounded-lg border transition ${
                    selectedConv.status === 'open'
                      ? 'border-gray-300 text-gray-700 hover:bg-gray-100'
                      : 'border-emerald-500 text-emerald-700 bg-emerald-50 hover:bg-emerald-100'
                  }`}
                >
                  {selectedConv.status === 'open' ? 'Mark as Resolved' : 'Re-open Ticket'}
                </button>
              </div>
            </div>

            {/* Messages Thread */}
            <div className="flex-1 p-6 overflow-y-auto space-y-4 bg-slate-50/40">
              {messages.length === 0 ? (
                <div className="py-20 text-center text-gray-400 text-xs">
                  No messages yet. Send a greeting to start chatting with this customer!
                </div>
              ) : (
                messages.map((msg) => {
                  const isAdmin = msg.sender_role === 'admin';
                  const isDriver = msg.sender_role === 'driver';
                  return (
                    <div
                      key={msg.id}
                      className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                    >
                      <div className="flex items-center gap-1.5 mb-1 px-1">
                        <span className="text-[10px] font-bold text-gray-400">
                          {isAdmin ? 'Staff / Support' : isDriver ? 'Delivery Driver' : msg.sender_name}
                        </span>
                        <span className="text-[9px] text-gray-400">
                          {new Date(msg.created_at).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                      </div>

                      <div
                        className={`max-w-[75%] rounded-2xl px-4 py-2.5 text-xs shadow-xs leading-relaxed ${
                          isAdmin
                            ? 'bg-quickopia-navy text-white rounded-br-none'
                            : isDriver
                            ? 'bg-emerald-600 text-white rounded-bl-none'
                            : 'bg-white text-slate-800 border border-gray-200 rounded-bl-none'
                        }`}
                      >
                        {msg.content}
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Quick Canned Replies */}
            <div className="px-6 py-2 border-t border-gray-100 bg-white flex items-center gap-2 overflow-x-auto text-[11px]">
              <span className="text-gray-400 font-bold shrink-0">Quick reply:</span>
              {[
                'Habari! Order yako inafungashwa sasa hivi.',
                'Dereva wako yuko njiani kuelekea eneo lako.',
                'Tumepokea taarifa yako, tunakutumia mbadala safi mara moja.',
                'Unaweza kumpa dereva msimbo wa OTP baada ya kukagua mzigo wako.',
              ].map((qr, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleQuickReply(qr)}
                  className="bg-gray-100 hover:bg-gray-200 text-slate-700 px-2.5 py-1 rounded-full whitespace-nowrap transition"
                >
                  {qr.substring(0, 32)}...
                </button>
              ))}
            </div>

            {/* Input Bar */}
            <form onSubmit={handleSend} className="p-4 border-t border-gray-200 bg-white flex gap-3">
              <input
                type="text"
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                placeholder="Type your reply to customer... (Press Enter to send)"
                className="flex-1 border border-gray-300 rounded-xl px-4 py-2.5 text-xs focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white"
              />
              <button
                type="submit"
                disabled={sending || !inputMessage.trim()}
                className="bg-quickopia-navy hover:bg-slate-900 disabled:opacity-50 text-white text-xs font-bold px-6 py-2.5 rounded-xl transition shadow-xs flex items-center gap-1.5"
              >
                {sending ? (
                  'Sending...'
                ) : (
                  <>
                    <Send className="w-3.5 h-3.5" />
                    <span>Send</span>
                  </>
                )}
              </button>
            </form>
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center text-center p-8 text-gray-400">
            <div>
              <MessageSquare className="w-10 h-10 text-gray-300 mx-auto mb-2" />
              <p className="text-xs font-bold">Select a customer conversation from the left to start chatting.</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
