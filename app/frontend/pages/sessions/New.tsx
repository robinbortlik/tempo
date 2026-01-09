import { Head, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";

interface PageProps {
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function Login() {
  const { flash } = usePage<PageProps>().props;
  const { data, setData, post, processing, errors } = useForm({
    email_address: "",
    password: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post("/session");
  }

  return (
    <>
      <Head title="Sign in" />
      <div className="min-h-screen flex items-center justify-center p-4 bg-stone-50">
        <div className="w-full max-w-sm">
          {/* Logo and Header */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-12 h-12 bg-stone-900 rounded-xl mb-4">
              <svg
                className="w-6 h-6 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <h1 className="text-2xl font-semibold text-stone-900">Tempo</h1>
            <p className="text-stone-500 mt-1">Time tracking & invoicing</p>
          </div>

          {/* Login Card */}
          <Card className="border-stone-200 shadow-sm">
            <CardContent className="p-6">
              {/* Flash Messages */}
              {flash.alert && (
                <div className="mb-4 p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm">
                  {flash.alert}
                </div>
              )}
              {flash.notice && (
                <div className="mb-4 p-3 rounded-lg bg-green-50 border border-green-200 text-green-700 text-sm">
                  {flash.notice}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <Label
                    htmlFor="email"
                    className="block text-sm font-medium text-stone-700 mb-1.5"
                  >
                    Email
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    value={data.email_address}
                    onChange={(e) => setData("email_address", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 placeholder:text-stone-400"
                    placeholder="you@example.com"
                    autoComplete="email"
                    autoFocus
                    required
                  />
                  {errors.email_address && (
                    <p className="mt-1 text-sm text-red-600">
                      {errors.email_address}
                    </p>
                  )}
                </div>

                <div>
                  <Label
                    htmlFor="password"
                    className="block text-sm font-medium text-stone-700 mb-1.5"
                  >
                    Password
                  </Label>
                  <Input
                    id="password"
                    type="password"
                    value={data.password}
                    onChange={(e) => setData("password", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                    autoComplete="current-password"
                    required
                  />
                  {errors.password && (
                    <p className="mt-1 text-sm text-red-600">
                      {errors.password}
                    </p>
                  )}
                </div>

                <Button
                  type="submit"
                  disabled={processing}
                  className="w-full py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
                >
                  {processing ? "Signing in..." : "Sign in"}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
}

// Opt out of the default layout for the login page
Login.layout = (page: React.ReactNode) => page;
