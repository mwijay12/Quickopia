import SupportInbox from '@/components/support/SupportInbox';

export const metadata = {
  title: 'Live Support Chat | Quickopia Supermarket Admin',
  description: 'In-app real-time live chat desk to converse with shoppers and drivers.',
};

export default function SupportPage() {
  return (
    <div className="space-y-6">
      <SupportInbox />
    </div>
  );
}
